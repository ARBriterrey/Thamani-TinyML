#include "main.h"
#include <string.h>
#include <stdio.h>

/* USER CODE BEGIN Includes */
/* USER CODE END Includes */

/* Private variables ---------------------------------------------------------*/
UART_HandleTypeDef huart1;
UART_HandleTypeDef huart2;

/* USER CODE BEGIN PV */
// Buffer size must match CHUNK_SIZE_ACTUAL used in the transfer loop
#define CHUNK_SIZE 2048
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
    // We will simulate sending a 2MB (2097152 bytes) ".bin" file.
    // Let's use 2048 byte chunks now to match the ESP32 buffer
    const uint32_t TOTAL_FILE_SIZE = 2097152;
    const uint32_t CHUNK_SIZE_ACTUAL = 2048;
    const uint32_t TOTAL_CHUNKS = TOTAL_FILE_SIZE / CHUNK_SIZE_ACTUAL;

    char tx_start_msg[64];
    snprintf(tx_start_msg, sizeof(tx_start_msg), "<INIT:%lu>", TOTAL_FILE_SIZE);
    
    char debug_start_msg[] = "\r\nInitiating 2MB File Transfer to ESP32...\r\n";
    HAL_UART_Transmit(&huart2, (uint8_t*)debug_start_msg, strlen(debug_start_msg), HAL_MAX_DELAY);
    
    // 1. Send INIT to ESP32
    HAL_UART_Transmit(&huart1, (uint8_t*)tx_start_msg, strlen(tx_start_msg), HAL_MAX_DELAY);

    // 2. Wait for <ACK_INIT> from ESP32
    uint8_t rx_byte = 0;
    char rx_buf[128] = {0};
    int rx_idx = 0;
    uint32_t start_tick = HAL_GetTick();
    uint8_t ack_received = 0;

    while (HAL_GetTick() - start_tick < 10000) {
        if (HAL_UART_Receive(&huart1, &rx_byte, 1, 10) == HAL_OK) {
            if (rx_byte == '>') {
                rx_buf[rx_idx] = '\0';
                if (strstr(rx_buf, "<ACK_INIT") != NULL) {
                    ack_received = 1;
                    break;
                }
                rx_idx = 0;
            } else if (rx_idx < sizeof(rx_buf) - 1) {
                rx_buf[rx_idx++] = rx_byte;
            }
        }
    }

    if (!ack_received) {
        char err_msg[] = "Failed to receive ACK_INIT. Retrying in 5s...\r\n";
        HAL_UART_Transmit(&huart2, (uint8_t*)err_msg, strlen(err_msg), HAL_MAX_DELAY);
        HAL_Delay(5000);
        continue;
    }

    char sending_msg[] = "ACK_INIT received. Streaming chunks...\r\n";
    HAL_UART_Transmit(&huart2, (uint8_t*)sending_msg, strlen(sending_msg), HAL_MAX_DELAY);

    // 3. Stream the file in chunks
    uint32_t total_computed_crc = 0; // Simple accumulated dummy CRC for this example
    
    for (uint32_t i = 0; i < TOTAL_CHUNKS; i++) {
        Generate_Dummy_Binary_Data(); 
        
        // Software CRC32 calculation (simplified dummy for now, replace with hardware CRC)
        uint32_t chunk_crc = 0;
        for (int b = 0; b < CHUNK_SIZE_ACTUAL; b++) {
            chunk_crc += dummy_data_buffer[b];
        }
        total_computed_crc += chunk_crc;
        
        uint8_t chunk_success = 0;
        int retries = 0;
        
        while (!chunk_success && retries < 3) {
            char tx_chunk_msg[64];
            snprintf(tx_chunk_msg, sizeof(tx_chunk_msg), "<CHUNK:%lu:%lu>", CHUNK_SIZE_ACTUAL, chunk_crc);
            HAL_UART_Transmit(&huart1, (uint8_t*)tx_chunk_msg, strlen(tx_chunk_msg), HAL_MAX_DELAY);
            
            // Wait for <READY>
            start_tick = HAL_GetTick();
            rx_idx = 0;
            uint8_t ready = 0;
            while (HAL_GetTick() - start_tick < 5000) {
                if (HAL_UART_Receive(&huart1, &rx_byte, 1, 10) == HAL_OK) {
                    if (rx_byte == '>') {
                        rx_buf[rx_idx] = '\0';
                        if (strstr(rx_buf, "<READY") != NULL) {
                            ready = 1;
                            break;
                        }
                        rx_idx = 0;
                    } else if (rx_idx < sizeof(rx_buf) - 1) {
                        rx_buf[rx_idx++] = rx_byte;
                    }
                }
            }
            
            if (ready) {
                HAL_UART_Transmit(&huart1, dummy_data_buffer, CHUNK_SIZE_ACTUAL, 2000);
                
                // Wait for <ACK_CHUNK>
                start_tick = HAL_GetTick();
                rx_idx = 0;
                while (HAL_GetTick() - start_tick < 15000) { // Server upload can take seconds
                    if (HAL_UART_Receive(&huart1, &rx_byte, 1, 10) == HAL_OK) {
                        if (rx_byte == '>') {
                            rx_buf[rx_idx] = '\0';
                            if (strstr(rx_buf, "<ACK_CHUNK") != NULL) {
                                chunk_success = 1;
                                break;
                            }
                            if (strstr(rx_buf, "<NACK_CHUNK") != NULL) {
                                break; // NACK received, retry
                            }
                            rx_idx = 0;
                        } else if (rx_idx < sizeof(rx_buf) - 1) {
                            rx_buf[rx_idx++] = rx_byte;
                        }
                    }
                }
            }
            
            if (!chunk_success) {
                retries++;
                char retry_msg[] = "Chunk failed. Retrying...\r\n";
                HAL_UART_Transmit(&huart2, (uint8_t*)retry_msg, strlen(retry_msg), HAL_MAX_DELAY);
            }
        }

        if (!chunk_success) {
             char err[] = "Max retries reached. Aborting.\r\n";
             HAL_UART_Transmit(&huart2, (uint8_t*)err, strlen(err), HAL_MAX_DELAY);
             break;
        }

        if (i % 64 == 0) { // Print debug every 64 chunks
            char status[32];
            snprintf(status, sizeof(status), "Sent %lu / %lu chunks\r\n", i, TOTAL_CHUNKS);
            HAL_UART_Transmit(&huart2, (uint8_t*)status, strlen(status), HAL_MAX_DELAY);
        }
    }

    // 4. Send End Marker
    char tx_end_msg[64];
    snprintf(tx_end_msg, sizeof(tx_end_msg), "<FINISH:%lu>", total_computed_crc);
    HAL_UART_Transmit(&huart1, (uint8_t*)tx_end_msg, strlen(tx_end_msg), HAL_MAX_DELAY);

    char done_msg[] = "Transfer Complete. Waiting for FINISH response...\r\n";
    HAL_UART_Transmit(&huart2, (uint8_t*)done_msg, strlen(done_msg), HAL_MAX_DELAY);

    // 5. Wait for Response from ESP32 (Timeout 30s)
    rx_idx = 0;
    memset(rx_buf, 0, sizeof(rx_buf));
    start_tick = HAL_GetTick();

    while (HAL_GetTick() - start_tick < 30000) {
        if (HAL_UART_Receive(&huart1, &rx_byte, 1, 10) == HAL_OK) {
            if (rx_byte == '>') {
                rx_buf[rx_idx] = '\0';
                if (strstr(rx_buf, "<ACK_FINISH:") != NULL || strstr(rx_buf, "<NACK_FINISH") != NULL) {
                    char resp_msg[256];
                    snprintf(resp_msg, sizeof(resp_msg), "ESP32 replies: %s>\r\n", rx_buf);
                    HAL_UART_Transmit(&huart2, (uint8_t*)resp_msg, strlen(resp_msg), HAL_MAX_DELAY);
                    break;
                }
                rx_idx = 0;
            } else if (rx_idx < sizeof(rx_buf) - 1) {
                rx_buf[rx_idx++] = rx_byte;
            }
        }
    }

    // Wait 15 seconds before sending the next file
    HAL_Delay(15000);
  }
  /* USER CODE END 3 */
}

/* USER CODE BEGIN 4 */

/**
  * @brief  System Clock Configuration — 84 MHz from HSI via PLL
  *         HSI 16MHz → PLL M=16 N=336 P=4 → 84MHz SYSCLK
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE2);

  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState       = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState   = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource  = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLM       = 16;
  RCC_OscInitStruct.PLL.PLLN       = 336;
  RCC_OscInitStruct.PLL.PLLP       = RCC_PLLP_DIV4;
  RCC_OscInitStruct.PLL.PLLQ       = 7;
  HAL_RCC_OscConfig(&RCC_OscInitStruct);

  RCC_ClkInitStruct.ClockType      = RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_SYSCLK
                                   | RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource   = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider  = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;
  HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2);
}

/**
  * @brief  GPIO Init — Enable clocks for GPIOA (used by USART1 + USART2)
  */
static void MX_GPIO_Init(void)
{
  __HAL_RCC_GPIOA_CLK_ENABLE();
}

/**
  * @brief  USART1 Init — ESP32 communication @ 115200 8N1
  *         TX: PA9   RX: PA10
  */
static void MX_USART1_UART_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  __HAL_RCC_USART1_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();

  GPIO_InitStruct.Pin       = GPIO_PIN_9 | GPIO_PIN_10;
  GPIO_InitStruct.Mode      = GPIO_MODE_AF_PP;
  GPIO_InitStruct.Pull      = GPIO_NOPULL;
  GPIO_InitStruct.Speed     = GPIO_SPEED_FREQ_VERY_HIGH;
  GPIO_InitStruct.Alternate = GPIO_AF7_USART1;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  huart1.Instance          = USART1;
  huart1.Init.BaudRate     = 115200;
  huart1.Init.WordLength   = UART_WORDLENGTH_8B;
  huart1.Init.StopBits     = UART_STOPBITS_1;
  huart1.Init.Parity       = UART_PARITY_NONE;
  huart1.Init.Mode         = UART_MODE_TX_RX;
  huart1.Init.HwFlowCtl    = UART_HWCONTROL_NONE;
  huart1.Init.OverSampling = UART_OVERSAMPLING_16;
  HAL_UART_Init(&huart1);
}

/**
  * @brief  USART2 Init — ST-Link USB debug @ 115200 8N1
  *         TX: PA2   RX: PA3
  */
static void MX_USART2_UART_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  __HAL_RCC_USART2_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();

  GPIO_InitStruct.Pin       = GPIO_PIN_2 | GPIO_PIN_3;
  GPIO_InitStruct.Mode      = GPIO_MODE_AF_PP;
  GPIO_InitStruct.Pull      = GPIO_NOPULL;
  GPIO_InitStruct.Speed     = GPIO_SPEED_FREQ_VERY_HIGH;
  GPIO_InitStruct.Alternate = GPIO_AF7_USART2;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  huart2.Instance          = USART2;
  huart2.Init.BaudRate     = 115200;
  huart2.Init.WordLength   = UART_WORDLENGTH_8B;
  huart2.Init.StopBits     = UART_STOPBITS_1;
  huart2.Init.Parity       = UART_PARITY_NONE;
  huart2.Init.Mode         = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl    = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  HAL_UART_Init(&huart2);
}

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
