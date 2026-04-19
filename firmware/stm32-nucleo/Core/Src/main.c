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
    // We will simulate sending a 2MB (2097152 bytes) ".bin" file.
    // 2097152 / 1024 (CHUNK_SIZE) = 2048 chunks
    const uint32_t TOTAL_FILE_SIZE = 2097152;
    const uint32_t TOTAL_CHUNKS = TOTAL_FILE_SIZE / CHUNK_SIZE;

    char tx_start_msg[64];
    snprintf(tx_start_msg, sizeof(tx_start_msg), "<START_BIN:%lu>", TOTAL_FILE_SIZE);
    
    char debug_start_msg[] = "\r\nInitiating 2MB File Transfer to ESP32...\r\n";
    HAL_UART_Transmit(&huart2, (uint8_t*)debug_start_msg, strlen(debug_start_msg), HAL_MAX_DELAY);
    
    // 1. Send Start Marker to ESP32
    HAL_UART_Transmit(&huart1, (uint8_t*)tx_start_msg, strlen(tx_start_msg), HAL_MAX_DELAY);

    // 2. Wait for <ACK_START> from ESP32 (Timeout 5 seconds)
    uint8_t rx_byte = 0;
    char rx_buf[32] = {0};
    int rx_idx = 0;
    uint32_t start_tick = HAL_GetTick();
    uint8_t ack_received = 0;

    char wait_msg[] = "Waiting for ACK...\r\n";
    HAL_UART_Transmit(&huart2, (uint8_t*)wait_msg, strlen(wait_msg), HAL_MAX_DELAY);

    while (HAL_GetTick() - start_tick < 5000) {
        if (HAL_UART_Receive(&huart1, &rx_byte, 1, 10) == HAL_OK) {
            if (rx_byte == '>') {
                rx_buf[rx_idx] = '\0';
                if (strstr(rx_buf, "<ACK_START") != NULL) {
                    ack_received = 1;
                    break;
                }
                rx_idx = 0; // Reset for next tag
            } else if (rx_idx < sizeof(rx_buf) - 1) {
                rx_buf[rx_idx++] = rx_byte;
            }
        }
    }

    if (!ack_received) {
        char err_msg[] = "Failed to receive ACK_START. Retrying in 5s...\r\n";
        HAL_UART_Transmit(&huart2, (uint8_t*)err_msg, strlen(err_msg), HAL_MAX_DELAY);
        HAL_Delay(5000);
        continue;
    }

    char sending_msg[] = "ACK received. Streaming 2048 chunks...\r\n";
    HAL_UART_Transmit(&huart2, (uint8_t*)sending_msg, strlen(sending_msg), HAL_MAX_DELAY);

    // 3. Stream the file in chunks
    for (uint32_t i = 0; i < TOTAL_CHUNKS; i++) {
        // Regenerate variations in data logic (optional, for realism)
        Generate_Dummy_Binary_Data(); 
        
        if (HAL_UART_Transmit(&huart1, dummy_data_buffer, CHUNK_SIZE, 1000) != HAL_OK) {
            char chunk_err[] = "Chunk TX Error!\r\n";
            HAL_UART_Transmit(&huart2, (uint8_t*)chunk_err, strlen(chunk_err), HAL_MAX_DELAY);
            break;
        }

        if (i % 256 == 0) { // Print debug every 256KB
            char status[32];
            snprintf(status, sizeof(status), "Sent %lu / 2048 chunks\r\n", i);
            HAL_UART_Transmit(&huart2, (uint8_t*)status, strlen(status), HAL_MAX_DELAY);
        }
    }

    // 4. Send End Marker
    char tx_end_msg[] = "<END_BIN>";
    HAL_UART_Transmit(&huart1, (uint8_t*)tx_end_msg, strlen(tx_end_msg), HAL_MAX_DELAY);

    char done_msg[] = "Transfer Complete. Waiting for Server Response...\r\n";
    HAL_UART_Transmit(&huart2, (uint8_t*)done_msg, strlen(done_msg), HAL_MAX_DELAY);

    // 5. Wait for Response from ESP32 (Timeout 30s)
    rx_idx = 0;
    memset(rx_buf, 0, sizeof(rx_buf));
    start_tick = HAL_GetTick();
    uint8_t resp_received = 0;

    while (HAL_GetTick() - start_tick < 30000) {
        if (HAL_UART_Receive(&huart1, &rx_byte, 1, 10) == HAL_OK) {
            if (rx_byte == '>') {
                rx_buf[rx_idx] = '\0';
                if (strstr(rx_buf, "<RESPONSE:") != NULL || strstr(rx_buf, "<ERROR:") != NULL) {
                    resp_received = 1;
                    char resp_msg[128];
                    snprintf(resp_msg, sizeof(resp_msg), "ESP32 says: %s>\r\n", rx_buf);
                    HAL_UART_Transmit(&huart2, (uint8_t*)resp_msg, strlen(resp_msg), HAL_MAX_DELAY);
                    break;
                }
                rx_idx = 0;
            } else if (rx_idx < sizeof(rx_buf) - 1) {
                rx_buf[rx_idx++] = rx_byte;
            }
        }
    }

    if (!resp_received) {
        char timeout_msg[] = "Server response timeout.\r\n";
        HAL_UART_Transmit(&huart2, (uint8_t*)timeout_msg, strlen(timeout_msg), HAL_MAX_DELAY);
    }

    // Wait 15 seconds before sending the next file
    HAL_Delay(15000);
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
