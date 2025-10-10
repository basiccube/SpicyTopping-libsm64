extern "C"
{
#include "libsm64.h"
#include "SDL.h"
}
#include "baseinc.h"
#include "pthread.h"
#include <png.h>

uint8_t* utils_read_file_alloc(const char* path, size_t* fileLength)
{
	FILE* f = fopen(path, "rb");
    if (!f)
        return NULL;

    fseek(f, 0, SEEK_END);
    size_t length = (size_t)ftell(f);
    rewind(f);

    uint8_t* buffer = (uint8_t*)malloc(length + 1);
    fread(buffer, 1, length, f);
    buffer[length] = 0;

    fclose(f);

    if (fileLength)
        *fileLength = length;

    return buffer;
}

static int save_png(const char* filename, int width, int height, int bitdepth, int colortype, unsigned char* data, int pitch, int transform)
{
    int i = 0;
    int r = 0;
    FILE* fp = NULL;
    png_structp png_ptr = NULL;
    png_infop info_ptr = NULL;
    png_bytep* row_pointers = NULL;

    if (data == NULL)
    {
        printf("Error: failed to save the png because the given data is NULL.\n");
        r = -1;
        goto error;
    }

    if (strlen(filename) == 0)
    {
        printf("Error: failed to save the png because the given filename length is 0.\n");
        r = -2;
        goto error;
    }

    if (pitch == 0)
    {
        printf("Error: failed to save the png because the given pitch is 0.\n");
        r = -3;
        goto error;
    }

    fp = fopen(filename, "wb");
    if (fp == NULL)
    {
        printf("Error: failed to open the png file: %s\n", filename);
        r = -4;
        goto error;
    }

    png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (png_ptr == NULL)
    {
        printf("Error: failed to create the png write struct.\n");
        r = -5;
        goto error;
    }

    info_ptr = png_create_info_struct(png_ptr);
    if (info_ptr == NULL)
    {
        printf("Error: failed to create the png info struct.\n");
        r = -6;
        goto error;
    }

    png_set_IHDR(png_ptr, info_ptr, width, height, bitdepth, colortype, PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

    row_pointers = (png_bytep*)malloc(sizeof(png_bytep) * height);

    for (i = 0; i < height; ++i)
    {
        row_pointers[i] = data + i * pitch;
    }

    png_init_io(png_ptr, fp);
    png_set_rows(png_ptr, info_ptr, row_pointers);
    png_write_png(png_ptr, info_ptr, transform, NULL);

error:
    if (fp != NULL)
    {
        fclose(fp);
        fp = NULL;
    }

    if (png_ptr != NULL)
    {
        if (info_ptr == NULL)
            printf("Error: info ptr is null. not supposed to happen here.\n");

        png_destroy_write_struct(&png_ptr, &info_ptr);
        png_ptr = NULL;
        info_ptr = NULL;
    }

    if (row_pointers != NULL)
    {
        free(row_pointers);
        row_pointers = NULL;
    }

    printf("And we're all free.\n");
    return r;
}

static SDL_AudioDeviceID dev;
pthread_t gSoundThread;

int gettimeofday(struct timeval* tp, struct timezone* tzp)
{
    // Note: some broken versions only have 8 trailing zero's, the correct epoch has 9 trailing zero's
    // This magic number is the number of 100 nanosecond intervals since January 1, 1601 (UTC)
    // until 00:00:00 January 1, 1970 
    static const uint64_t EPOCH = ((uint64_t)116444736000000000ULL);

    SYSTEMTIME  system_time;
    FILETIME    file_time;
    uint64_t    time;

    GetSystemTime(&system_time);
    SystemTimeToFileTime(&system_time, &file_time);
    time = ((uint64_t)file_time.dwLowDateTime);
    time += ((uint64_t)file_time.dwHighDateTime) << 32;

    tp->tv_sec = (long)((time - EPOCH) / 10000000L);
    tp->tv_usec = (long)(system_time.wMilliseconds * 1000);
    return 0;
}

long long time_in_milliseconds()
{
    struct timeval tv;
    gettimeofday(&tv, NULL);

    return (((long long)tv.tv_sec) * 1000) + (tv.tv_usec / 1000);
}

void* audio_thread(void* p)
{
    pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL);
    pthread_setcanceltype(PTHREAD_CANCEL_DEFERRED, NULL);

    long long currentTime = time_in_milliseconds();
    long long targetTime = 0;

    while (1)
    {
        int16_t audioBuffer[544 * 2 * 2];
        uint32_t numSamples = sm64_audio_tick(SDL_GetQueuedAudioSize(dev) / 4, 1100, audioBuffer);
        if (SDL_GetQueuedAudioSize(dev) / 4 < 6000)
            SDL_QueueAudio(dev, audioBuffer, numSamples * 2 * 4);

        targetTime = currentTime + 33;
        while (time_in_milliseconds() < targetTime)
            Sleep(100);
        currentTime = time_in_milliseconds();
    }

    return p;
}

static struct SM64MarioInputs marioInputs;
static struct SM64MarioState marioState;
static struct SM64MarioGeometryBuffers marioGeometry;
static struct SM64Surface* surfaces;
static size_t surfaces_count;

func double libsm64_init()
{
    size_t romSize;
    uint8_t* rom = utils_read_file_alloc("sm64.us.z64", &romSize);

    if (!rom)
        return false;

    uint8_t* texture = (uint8_t*)malloc(4 * SM64_TEXTURE_WIDTH * SM64_TEXTURE_HEIGHT);

    sm64_global_terminate();
    sm64_global_init(rom, texture);
    sm64_audio_init(rom);

    save_png("sm64_texture.png", SM64_TEXTURE_WIDTH, SM64_TEXTURE_HEIGHT, 8, PNG_COLOR_TYPE_RGB_ALPHA, texture, 4 * SM64_TEXTURE_WIDTH, PNG_TRANSFORM_IDENTITY);

    // init audio
    if (SDL_InitSubSystem(SDL_INIT_AUDIO) < 0)
        printf("SDL_InitSubSystem failed: %s\n", SDL_GetError());

    SDL_AudioSpec want, have;
    SDL_zero(want);

    want.freq = 32000;
    want.format = AUDIO_S16;
    want.channels = 2;
    want.samples = 512;
    want.callback = NULL;

    dev = SDL_OpenAudioDevice(NULL, 0, &want, &have, 0);
    if (dev == 0)
        printf("SDL_OpenAudio error: %s\n", SDL_GetError());
    SDL_PauseAudioDevice(dev, 0);

    pthread_create(&gSoundThread, NULL, audio_thread, NULL);

    free(texture);
    free(rom);
    
    surfaces = 0;
    surfaces_count = 0;

	return true;
}

func double libsm64_mario_create(double x, double y, double z)
{
    int32_t marioID = sm64_mario_create((float)x, (float)y, (float)z);

    marioGeometry.position = (float*)malloc(sizeof(float) * 9 * SM64_GEO_MAX_TRIANGLES);
    marioGeometry.color = (float*)malloc(sizeof(float) * 9 * SM64_GEO_MAX_TRIANGLES);
    marioGeometry.normal = (float*)malloc(sizeof(float) * 9 * SM64_GEO_MAX_TRIANGLES);
    marioGeometry.uv = (float*)malloc(sizeof(float) * 6 * SM64_GEO_MAX_TRIANGLES);
    marioGeometry.numTrianglesUsed = 0;

    return (double)marioID;
}

func double libsm64_mario_set_input(double id, double A, double B, double Z, double camX, double camZ, double stickX, double stickY)
{
    marioInputs.buttonA = (uint8_t)A;
    marioInputs.buttonB = (uint8_t)B;
    marioInputs.buttonZ = (uint8_t)Z;
    marioInputs.camLookX = marioState.position[0] - camX;
    marioInputs.camLookZ = marioState.position[2] - camZ;
    marioInputs.stickX = stickX;
    marioInputs.stickY = stickY;

    return false;
}

func double libsm64_mario_tick(double id)
{
    sm64_mario_tick((int)id, &marioInputs, &marioState, &marioGeometry);
    return true;
}

func double libsm64_mario_get_triangles_used(double id)
{
    return marioGeometry.numTrianglesUsed;
}

func double libsm64_mario_get_posX(double id)
{
    return marioState.position[0];
}

func double libsm64_mario_get_posY(double id)
{
    return marioState.position[1];
}

func double libsm64_mario_get_posZ(double id)
{
    return marioState.position[2];
}

func double libsm64_mario_get_velX(double id)
{
    return marioState.velocity[0];
}

func double libsm64_mario_get_velY(double id)
{
    return marioState.velocity[1];
}

func double libsm64_mario_get_velZ(double id)
{
    return marioState.velocity[2];
}

func double libsm64_mario_get_geometry_posX(double id, double triangleVertex)
{
    return marioGeometry.position[(int)triangleVertex + 0];
}

func double libsm64_mario_get_geometry_posY(double id, double triangleVertex)
{
    return marioGeometry.position[(int)triangleVertex + 1];
}

func double libsm64_mario_get_geometry_posZ(double id, double triangleVertex)
{
    return marioGeometry.position[(int)triangleVertex + 2];
}

func double libsm64_mario_get_geometry_normalX(double id, double triangleVertex)
{
    return marioGeometry.normal[(int)triangleVertex + 0];
}

func double libsm64_mario_get_geometry_normalY(double id, double triangleVertex)
{
    return marioGeometry.normal[(int)triangleVertex + 1];
}

func double libsm64_mario_get_geometry_normalZ(double id, double triangleVertex)
{
    return marioGeometry.normal[(int)triangleVertex + 2];
}

func double libsm64_mario_get_geometry_colorRed(double id, double triangleVertex)
{
    return marioGeometry.color[(int)triangleVertex + 0] * 255;
}

func double libsm64_mario_get_geometry_colorGreen(double id, double triangleVertex)
{
    return marioGeometry.color[(int)triangleVertex + 1] * 255;
}

func double libsm64_mario_get_geometry_colorBlue(double id, double triangleVertex)
{
    return marioGeometry.color[(int)triangleVertex + 2] * 255;
}

func double libsm64_mario_get_geometry_uvX(double id, double vertex)
{
    return marioGeometry.uv[(int)vertex + 0];
}

func double libsm64_mario_get_geometry_uvY(double id, double vertex)
{
    return marioGeometry.uv[(int)vertex + 1];
}

func double libsm64_mario_get_faceangle(double id)
{
    return marioState.faceAngle;
}

func double libsm64_mario_get_health(double id)
{
    return marioState.health >> 8;
}

func double libsm64_mario_get_action(double id)
{
    return marioState.action;
}

func double libsm64_mario_get_flags(double id)
{
    return marioState.flags;
}

func double libsm64_mario_get_particleflags(double id)
{
    return marioState.particleFlags;
}

func double libsm64_mario_get_invictimer(double id)
{
    return marioState.invincTimer;
}

func double libsm64_mario_set_position(double id, double x, double y, double z)
{
    sm64_set_mario_position((int32_t)id, x, y, z);
    return true;
}

func double libsm64_mario_set_posZ(double id, double z)
{
    sm64_set_mario_posZ((int32_t)id, z);
    return true;
}

func double libsm64_mario_set_angle(double id, double x, double y, double z)
{
    sm64_set_mario_angle((int32_t)id, x, y, z);
    return true;
}

func double libsm64_mario_set_faceangle(double id, double y)
{
    sm64_set_mario_faceangle((int32_t)id, y);
    return true;
}

func double libsm64_mario_set_action(double id, double action)
{
    sm64_set_mario_action((int32_t)id, (uint32_t)action);
    return true;
}

func double libsm64_mario_set_action_arg(double id, double action, double actionarg)
{
    sm64_set_mario_action_arg((int32_t)id, (uint32_t)action, (uint32_t)actionarg);
    return true;
}

func double libsm64_mario_set_animation(double id, double animID)
{
    sm64_set_mario_animation((int32_t)id, (int32_t)animID);
    return true;
}

func double libsm64_mario_set_animframe(double id, double animFrame)
{
    sm64_set_mario_anim_frame((int32_t)id, (int16_t)animFrame);
    return true;
}

func double libsm64_mario_set_state(double id, double flags)
{
    sm64_set_mario_state((int32_t)id, (uint32_t)flags);
    return true;
}

func double libsm64_mario_set_velocity(double id, double x, double y, double z)
{
    sm64_set_mario_velocity((int32_t)id, x, y, z);
    return true;
}

func double libsm64_mario_set_forward_velocity(double id, double vel)
{
    sm64_set_mario_forward_velocity((int32_t)id, vel);
    return true;
}

func double libsm64_mario_set_invincibility(double id, double timer)
{
    sm64_set_mario_invincibility((int32_t)id, (int16_t)timer);
    return true;
}

func double libsm64_mario_set_water_level(double id, double level)
{
    sm64_set_mario_water_level((int32_t)id, (signed int)level);
    return true;
}

func double libsm64_mario_set_gas_level(double id, double level)
{
    sm64_set_mario_gas_level((int32_t)id, (signed int)level);
    return true;
}

func double libsm64_mario_set_health(double id, double health)
{
    sm64_set_mario_health((int32_t)id, ((uint16_t)health) << 8);
    return true;
}

func double libsm64_mario_take_damage(double id, double damage, double subtype, double x, double y, double z)
{
    sm64_mario_take_damage((int32_t)id, (uint32_t)damage, (uint32_t)subtype, x, y, z);
    return true;
}

func double libsm64_mario_heal(double id, double healCounter)
{
    sm64_mario_heal((int32_t)id, (uint8_t)healCounter);
    return true;
}

func double libsm64_mario_kill(double id)
{
    sm64_mario_kill((int32_t)id);
    return true;
}

func double libsm64_add_static_surface(double surfaceType, double force, double terrainType, double v00, double v01, double v02, double v10, double v11, double v12, double v20, double v21, double v22)
{
    surfaces_count++;
    surfaces = (struct SM64Surface*)realloc(surfaces, sizeof(struct SM64Surface) * surfaces_count);
    surfaces[surfaces_count - 1].type = (int16_t)surfaceType;
    surfaces[surfaces_count - 1].force = (int16_t)force;
    surfaces[surfaces_count - 1].terrain = (uint16_t)terrainType;

    double vertices[3][3] = {
        {v00,v01,v02},
        {v10,v11,v12},
        {v20,v21,v22}
    };

    for (int i = 0; i < 3; i++)
    {
        for (int j = 0; j < 3; j++)
        {
            surfaces[surfaces_count - 1].vertices[i][j] = (int32_t)vertices[i][j];
        }
    }

    return surfaces_count;
}

func double libsm64_load_static_surfaces()
{
    sm64_unload_surfaces();
    sm64_static_surfaces_load(surfaces, surfaces_count);
    return surfaces_count;
}

func double libsm64_reset_surfaces()
{
	sm64_unload_surfaces();
	surfaces = 0;
    surfaces_count = 0;

    return true;
}

func double libsm64_get_static_surface(double ind, double vertInd)
{
    if (ind < 0 || ind >= surfaces_count || vertInd < 0 || vertInd >= 9)
        return 0;

    int i = ((int)vertInd) / 3;
    int j = ((int)vertInd) % 3;
    return surfaces[(int)ind].vertices[i][j];
}