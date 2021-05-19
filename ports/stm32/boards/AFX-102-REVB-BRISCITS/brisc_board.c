#include <brisc_board.h>
#include <brisc_thread.h>
#include <brisc_delay.h>
#include <xprintf.h>
#include <systick.h>
#include <microamp.h>

#include <string.h>

#define APP_CLOCK_TASK        "clock"
#define APP_CLOCK_ENDPOINT    "clock"
#define APP_CLOCK_SHM         256

#define APP_ECHO_TASK          "echo"
#define APP_ECHO_ENDPOINT0     "echo0"
#define APP_ECHO_ENDPOINT1     "echo1"
#define APP_ECHO_SHM           256

#define EVER            ;;
#define STACK_BYTES     (1024)
#define STACK_WORDS     STACK_BYTES / sizeof(cpu_reg_t)
#define STM32_MAIN_STACK_WORDS ((1024*4) / sizeof(cpu_reg_t))

typedef struct _app_state_ {

    cpu_reg_t stm32_main_stack[ STM32_MAIN_STACK_WORDS ];
    cpu_reg_t clock_stack [ STACK_WORDS ];
    cpu_reg_t echo_stack  [ STACK_WORDS ];

    int main_thread_handle;
    int stm32_main_thread_handle;

    int clock_thread_handle;
    int clock_microamp_handle;

    int echo_thread_handle;
    int echo_microamp_handle0;
    int echo_microamp_handle1;
 

    microamp_state_t microamp;

} app_state_t;

app_state_t app_state;

cpu_reg_t sstack = 0;                         
cpu_reg_t estack = 0;

extern void stm32_main(void* arg);
static void run_clock(void* arg);
static void run_echo(void* arg);

uint32_t brisc_board_clkfreq( void )
{
    return SystemCoreClock;
}

int main(int argc,char** argv)
{
    for(;;)
    {
        microamp_poll_hook();
        b_thread_yield();
    }
}

/* get here before main() */
void board_init()
{
    brisc_board_init();
    
    b_int_enable();
}

/* get here after main() */
void brisc_board_init(void) 
{
    memset(&app_state,0,sizeof(app_state_t));
    microamp_init(&app_state.microamp);

    sstack = (cpu_reg_t)&app_state.stm32_main_stack[0];                         
    estack = (cpu_reg_t)&app_state.stm32_main_stack[STM32_MAIN_STACK_WORDS];

    if ( (app_state.main_thread_handle  = b_thread_init( "main" )) >= 0 )
    {
        b_thread_set_systick_fn( SysTick_Handler );
        b_thread_set_yield_fn( PendSV_Handler );

        if ( (app_state.clock_thread_handle = b_thread_create( APP_CLOCK_TASK, run_clock, NULL, app_state.clock_stack, STACK_WORDS )) >= 0)
        {
            if ( (app_state.echo_thread_handle = b_thread_create( APP_ECHO_TASK, run_echo, NULL, app_state.echo_stack, STACK_WORDS )) >= 0)
            {
                if ( (app_state.stm32_main_thread_handle = b_thread_create( "stm32main", stm32_main, NULL, app_state.stm32_main_stack, STM32_MAIN_STACK_WORDS )) >= 0)
                {
                    b_thread_start( app_state.stm32_main_thread_handle );
                    b_thread_start( app_state.clock_thread_handle );
                    b_thread_start( app_state.echo_thread_handle );
                }
            }
        }
    }
}

/** *************************************************************************  
******************************** Clock Service *******************************
****************************************************************************/

static void run_clock(void* arg)
{
    microamp_create(&app_state.microamp,APP_CLOCK_ENDPOINT,APP_CLOCK_SHM);
    app_state.clock_microamp_handle = microamp_open(&app_state.microamp,APP_CLOCK_ENDPOINT);
    brisc_systick_t timeout_start=b_thread_systick();
    for(EVER)
    {
        if ( b_thread_systick() - timeout_start >= 10 )
        {
            timeout_start=b_thread_systick();
            if ( app_state.clock_microamp_handle >= 0 )
            {
                microamp_write(&app_state.microamp,app_state.clock_microamp_handle,
                                    &timeout_start,
                                    sizeof(timeout_start));
            }
        }
        b_thread_yield();
    }
}

/** *************************************************************************  
******************************** Echo Service *******************************
****************************************************************************/

static void echo_dataready_event(void* arg);

static char* echo_data_write = ">";
static char* echo_data_read[256];
static int echo_data_len = 0;

static void run_echo(void* arg)
{
    echo_data_len = strlen(echo_data_write);
    
    microamp_create(&app_state.microamp,APP_ECHO_ENDPOINT0,APP_ECHO_SHM);
    microamp_create(&app_state.microamp,APP_ECHO_ENDPOINT1,APP_ECHO_SHM);
    
    app_state.echo_microamp_handle0 = microamp_open(&app_state.microamp,APP_ECHO_ENDPOINT0);
    app_state.echo_microamp_handle1 = microamp_open(&app_state.microamp,APP_ECHO_ENDPOINT1);
    
    microamp_dataready_handler(&app_state.microamp,app_state.echo_microamp_handle1,echo_dataready_event,&app_state);

    microamp_write(&app_state.microamp,app_state.echo_microamp_handle0,echo_data_write,echo_data_len);

    for(EVER)
    {
        b_thread_yield();
    }
}

static void echo_dataready_event(void* arg)
{
    app_state_t* app_state = (app_state_t*)arg;
    while ( microamp_read(&app_state->microamp,app_state->echo_microamp_handle1,echo_data_read,echo_data_len) > 0 )
        b_thread_yield();
    microamp_write(&app_state->microamp,app_state->echo_microamp_handle0,echo_data_write,echo_data_len);
}
