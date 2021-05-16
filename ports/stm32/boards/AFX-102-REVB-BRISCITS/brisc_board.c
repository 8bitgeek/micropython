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

typedef struct _app_state_ {

    cpu_reg_t clock_stack [ STACK_WORDS ];
    cpu_reg_t echo_stack  [ STACK_WORDS ];

    int main_thread_handle;

    int clock_thread_handle;
    int clock_microamp_handle;
    
    int echo_thread_handle;
    int echo_microamp_handle0;
    int echo_microamp_handle1;
 
    microamp_state_t microamp;

} app_state_t;

app_state_t app_state;

static void run_clock  (void* arg);
static void run_echo(void* arg);

uint32_t brisc_board_clkfreq( void )
{
    return SystemCoreClock;
}

/* get here before main() */
void board_init()
{
}

/* get here after main() */
void brisc_board_init(void) 
{
    memset(&app_state,0,sizeof(app_state_t));
    microamp_init(&app_state.microamp);
    if ( (app_state.main_thread_handle  = b_thread_init( "main" )) >= 0 )
    {
        b_thread_set_systick_fn( SysTick_Handler );
        b_thread_set_yield_fn( PendSV_Handler );

        if ( (app_state.clock_thread_handle = b_thread_create( APP_CLOCK_TASK, run_clock, NULL, app_state.clock_stack, STACK_WORDS )) >= 0)
        {
            if ( (app_state.echo_thread_handle = b_thread_create( APP_ECHO_TASK, run_echo, NULL, app_state.echo_stack, STACK_WORDS )) >= 0)
            {
                b_thread_start( app_state.clock_thread_handle );
                b_thread_start( app_state.echo_thread_handle );
            }
        }
    }
    b_int_enable();
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
