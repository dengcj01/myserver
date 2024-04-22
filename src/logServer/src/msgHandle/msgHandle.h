#pragma once

#include <stdint.h>
#include <stddef.h>






void writeLogData(uint64_t sessionId, char *data, size_t len);   
void writeMailData(uint64_t sessionId, char *data, size_t len);     
void reqGameQuit(uint64_t sessionId, char *data, size_t len);      






void dispatchClientMessage(uint16_t messageId, uint64_t sessionId, char* data, size_t len);