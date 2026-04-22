#include "main.h"
#include <string.h>

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
