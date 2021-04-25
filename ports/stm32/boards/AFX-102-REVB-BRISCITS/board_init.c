#include STM32_HAL_H

#include <systick.h>

/* MicroPython PendSV and SysTick ISRs */
extern void PendSV_Handler(void);
extern void SysTick_Handler(void);

#if 1

#include <brisc_thread.h>
#include <brisc_delay.h>
#include <string.h>

#define EVER            ;;
#define STACK_BYTES     (1024)
#define STACK_WORDS     STACK_BYTES / sizeof(cpu_reg_t)

static cpu_reg_t red_stack   [ STACK_WORDS ];
static cpu_reg_t green_stack [ STACK_WORDS ];
static cpu_reg_t blue_stack  [ STACK_WORDS ];

static int red_thread_handle   = (-1);
static int green_thread_handle = (-1);
static int blue_thread_handle  = (-1);
static int main_thread_handle  = (-1);

typedef struct _app_state_ {
    float red_count;
    float green_count;
    float blue_count;
    float main_count;
} app_state_t;

app_state_t app_state;

static void run_red  (void* arg);
static void run_green(void* arg);
static void run_blue (void* arg);

static void run_red(void* arg)
{
    brisc_systick_t timeout_start=b_thread_systick();

    for(EVER)
    {
        if ( b_thread_systick() - timeout_start >= 1 )
        {
            app_state.red_count += 0.001f;
            timeout_start=b_thread_systick();
        }
        b_thread_yield();
    }
}

static void run_green(void* arg)
{
    brisc_systick_t timeout_start=b_thread_systick();

    for(EVER)
    {
        if ( b_thread_systick() - timeout_start >= 1 )
        {
            app_state.green_count += 0.001f;
            timeout_start=b_thread_systick();
        }
        b_thread_yield();
    }
}

static void run_blue(void* arg)
{
    brisc_systick_t timeout_start=b_thread_systick();

    for(EVER)
    {
        if ( b_thread_systick() - timeout_start >= 1 )
        {
            app_state.blue_count += 0.001f;
            timeout_start=b_thread_systick();
        }
        b_thread_yield();
    }
}

void AFX_102_REVB_PRISCITS_board_early_init(void) 
{
    memset(&app_state,0,sizeof(app_state_t));
    if ( (main_thread_handle  = b_thread_init( "main" )) >= 0 )
    {
        b_thread_set_systick_fn( SysTick_Handler );
        b_thread_set_yield_fn( PendSV_Handler );

        if ( (red_thread_handle = b_thread_create( "red", run_red, NULL, red_stack, STACK_WORDS )) >= 0)
        {
            if ( (green_thread_handle = b_thread_create( "green", run_green, NULL, green_stack, STACK_WORDS )) >= 0)
            {
                if ( (blue_thread_handle = b_thread_create( "blue", run_blue, NULL, blue_stack, STACK_WORDS )) >= 0)
                {
                    b_thread_start( red_thread_handle );
                    b_thread_start( blue_thread_handle );
                    b_thread_start( green_thread_handle );
                }
            }
        }
    }
    b_int_enable();
}

#else

extern void PendSV_IRQ_Handler(void)
{
    PendSV_Handler();
}

extern void SysTick_IRQ_Handler(void)
{
    SysTick_Handler();
}

void AFX_102_REVB_PRISCITS_board_early_init(void) 
{
}

#endif