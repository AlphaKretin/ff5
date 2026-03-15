#ifdef FF5_AUDIO_SDL2

#include "SDL2AudioOutput.h"
#include <SDL2/SDL.h>
#include <cstdio>

SDL2AudioOutput::~SDL2AudioOutput() {
    shutdown();
}

bool SDL2AudioOutput::init(int sampleRate, int channels) {
    if (SDL_Init(SDL_INIT_AUDIO) != 0) {
        SDL_Log("SDL_Init(AUDIO) failed: %s", SDL_GetError());
        return false;
    }

    SDL_AudioSpec desired{};
    desired.freq     = sampleRate;
    desired.format   = AUDIO_F32SYS;   // float32, native byte order
    desired.channels = static_cast<uint8_t>(channels);
    desired.samples  = 1024;           // buffer size in frames
    desired.callback = nullptr;        // push model via SDL_QueueAudio

    SDL_AudioSpec obtained{};
    m_device = SDL_OpenAudioDevice(nullptr, 0, &desired, &obtained,
                                   SDL_AUDIO_ALLOW_FREQUENCY_CHANGE);
    if (m_device == 0) {
        SDL_Log("SDL_OpenAudioDevice failed: %s", SDL_GetError());
        return false;
    }

    m_sampleRate = obtained.freq;
    m_channels   = obtained.channels;

    SDL_PauseAudioDevice(m_device, 0);  // start playback
    return true;
}

void SDL2AudioOutput::shutdown() {
    if (m_device != 0) {
        SDL_CloseAudioDevice(m_device);
        m_device = 0;
    }
    SDL_QuitSubSystem(SDL_INIT_AUDIO);
}

void SDL2AudioOutput::submitSamples(const float* samples, int count) {
    if (m_device == 0) return;
    SDL_QueueAudio(m_device, samples, static_cast<uint32_t>(count * sizeof(float)));
}

int SDL2AudioOutput::queuedFrames() const {
    if (m_device == 0 || m_channels == 0) return 0;
    uint32_t queuedBytes = SDL_GetQueuedAudioSize(m_device);
    return static_cast<int>(queuedBytes / (sizeof(float) * m_channels));
}

#endif // FF5_AUDIO_SDL2
