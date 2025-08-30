//
//  SharedCameraBuffer.hpp
//  MacCameraStreamer
//
//  Created by Jagadish Paul on 28/07/25.



#ifndef SHARED_CAMERA_BUFFER_HPP
#define SHARED_CAMERA_BUFFER_HPP

#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <sys/stat.h>
#include <cstring>
#include <cstdio>

#define WIDTH 1280
#define HEIGHT 720
#define CHANNELS 4
#define FRAME_SIZE (WIDTH * HEIGHT * CHANNELS)

class SharedCameraBuffer {
public:
    uint8_t* buffer = nullptr;
    int shm_fd = -1;
    const char* path;

    bool initialize(bool isWriter, const char* filePath) {
        path = filePath;

        shm_fd = open(filePath, O_CREAT | O_RDWR, 0600);
        if (shm_fd == -1) {
            perror("open");
            return false;
        }

        if (ftruncate(shm_fd, FRAME_SIZE) == -1) {
            perror("ftruncate");
            close(shm_fd);
            return false;
        }

        buffer = (uint8_t*)mmap(nullptr, FRAME_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);
        if (buffer == MAP_FAILED) {
            perror("mmap");
            close(shm_fd);
            return false;
        }

        return true;
    }

    void writeFrame(const uint8_t* data) {
        if (!buffer) return;
        memcpy(buffer, data, FRAME_SIZE);
        msync(buffer, FRAME_SIZE, MS_SYNC);
    }

    void cleanup() {
        if (buffer) {
            munmap(buffer, FRAME_SIZE);
            buffer = nullptr;
        }
        if (shm_fd != -1) {
            close(shm_fd);
            shm_fd = -1;
        }
    }
};

#endif
