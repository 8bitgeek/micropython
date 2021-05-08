#include <brisc_board.h>
#include <brisc_thread.h>
#include <brisc_delay.h>
#include <xprintf.h>
#include <systick.h>
#include <microamp.h>

#include <string.h>

#define APP_CLOCK_TASK        "clock"
#define APP_CLOCK_ENDPOINT    "clock"
#define APP_CLOCK_SHM         128

#define APP_EZBUS_TASK          "ezbus"
#define APP_EZBUS_ENDPOINT      "ezbus0"
#define APP_EZBUS_SHM           512

#define EVER            ;;
#define STACK_BYTES     (1024)
#define STACK_WORDS     STACK_BYTES / sizeof(cpu_reg_t)

typedef struct _app_state_ {

    cpu_reg_t clock_stack   [ STACK_WORDS ];
    cpu_reg_t ezbus_stack   [ STACK_WORDS ];

    int main_thread_handle;

    int clock_thread_handle;
    int clock_microamp_handle;
    
    int ezbus_thread_handle;
    int ezbus_microamp_handle;
 
    microamp_state_t microamp;

} app_state_t;

app_state_t app_state;

static void run_clock  (void* arg);
static void run_ezbus(void* arg);

uint32_t brisc_board_clkfreq( void )
{
    return SystemCoreClock;
}

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
            if ( (app_state.ezbus_thread_handle = b_thread_create( APP_EZBUS_TASK, run_ezbus, NULL, app_state.ezbus_stack, STACK_WORDS )) >= 0)
            {
                b_thread_start( app_state.clock_thread_handle );
                b_thread_start( app_state.ezbus_thread_handle );
            }
        }
    }
    b_int_enable();
}

static void run_clock(void* arg)
{
    microamp_create(&app_state.microamp,APP_CLOCK_ENDPOINT,APP_CLOCK_SHM);
    app_state.clock_microamp_handle = microamp_open(&app_state.microamp,APP_CLOCK_ENDPOINT);
    brisc_systick_t timeout_start=b_thread_systick();
    for(EVER)
    {
        if ( b_thread_systick() - timeout_start >= 1000 )
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

static void run_ezbus(void* arg)
{
    brisc_systick_t timeout_start=b_thread_systick();
    microamp_create(&app_state.microamp,APP_EZBUS_ENDPOINT,APP_EZBUS_SHM);
    app_state.ezbus_microamp_handle = microamp_open(&app_state.microamp,APP_EZBUS_ENDPOINT);
    for(EVER)
    {
        if ( b_thread_systick() - timeout_start >= 1 )
        {
            timeout_start=b_thread_systick();
        }
        b_thread_yield();
    }
}
