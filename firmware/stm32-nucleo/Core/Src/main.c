#include "main.h"
#include <string.h>

/* USER CODE BEGIN Includes */
/* USER CODE END Includes */

/* Private variables ---------------------------------------------------------*/
UART_HandleTypeDef huart1;
UART_HandleTypeDef huart2;

/* USER CODE BEGIN PV */
// Dummy binary data file structure to simulate a .CDQ file or chunk
#define CHUNK_SIZE 1024
uint8_t dummy_data_buffer[CHUNK_SIZE];

// UART Transmission Flags
volatile uint8_t tx_complete = 0;
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART1_UART_Init(void); // ESP32 Communication
static void MX_USART2_UART_Init(void); // ST-Link Debug
/* USER CODE BEGIN PFP */
void Generate_Dummy_Binary_Data(void);
/* USER CODE END PFP */

int main(void)
{
  /* MCU Configuration--------------------------------------------------------*/
  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* Configure the system clock */
  SystemClock_Config();

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_USART1_UART_Init();
  MX_USART2_UART_Init();

  /* USER CODE BEGIN 2 */
  // Debug Message
  char debug_msg[] = "STM32 Initiated. Generating dummy binary data...\r\n";
  HAL_UART_Transmit(&huart2, (uint8_t*)debug_msg, strlen(debug_msg), HAL_MAX_DELAY);

  Generate_Dummy_Binary_Data();
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    // Transmit the 1KB dummy binary chunk to ESP32 over USART1 using DMA or Interrupt
    // We will use standard blocking mode for the simplest initial test
    char tx_start_msg[] = "Sending 1KB chunk to ESP32...\r\n";
    HAL_UART_Transmit(&huart2, (uint8_t*)tx_start_msg, strlen(tx_start_msg), HAL_MAX_DELAY);

    // Send binary dummy data
    if(HAL_UART_Transmit(&huart1, dummy_data_buffer, CHUNK_SIZE, 5000) == HAL_OK) {
        char tx_ok_msg[] = "Chunk sent successfully.\r\n";
        HAL_UART_Transmit(&huart2, (uint8_t*)tx_ok_msg, strlen(tx_ok_msg), HAL_MAX_DELAY);
    } else {
        char tx_err_msg[] = "Error sending chunk.\r\n";
        HAL_UART_Transmit(&huart2, (uint8_t*)tx_err_msg, strlen(tx_err_msg), HAL_MAX_DELAY);
    }

    // Wait 2 seconds before sending the next chunk
    HAL_Delay(2000);
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
}

/* USER CODE BEGIN 4 */
// Function to fill the buffer with dummy binary data
// Simulating the 3 dummy signals at 500Hz
void Generate_Dummy_Binary_Data(void) {
    uint16_t sample_analog = 0;
    uint16_t sample_ppg1 = 1000;
    uint16_t sample_ppg2 = 2000;

    for (int i = 0; i < CHUNK_SIZE; i += 6) { // 6 bytes per sample set (3 x 16-bit)
        // Simulate varying the data slightly
        sample_analog = (sample_analog + 1) % 4096;
        sample_ppg1 = (sample_ppg1 + 2) % 4096;
        sample_ppg2 = (sample_ppg2 + 3) % 4096;

        if (i + 1 < CHUNK_SIZE) {
            dummy_data_buffer[i] = sample_analog & 0xFF;           // LSB
            dummy_data_buffer[i+1] = (sample_analog >> 8) & 0xFF;  // MSB
        }
        if (i + 3 < CHUNK_SIZE) {
            dummy_data_buffer[i+2] = sample_ppg1 & 0xFF;
            dummy_data_buffer[i+3] = (sample_ppg1 >> 8) & 0xFF;
        }
        if (i + 5 < CHUNK_SIZE) {
            dummy_data_buffer[i+4] = sample_ppg2 & 0xFF;
            dummy_data_buffer[i+5] = (sample_ppg2 >> 8) & 0xFF;
        }
    }
}
/* USER CODE END 4 */
