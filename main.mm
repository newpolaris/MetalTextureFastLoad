#define GLFW_INCLUDE_NONE
#define GLFW_EXPOSE_NATIVE_COCOA
#include <GLFW/glfw3.h>
#include <GLFW/glfw3native.h>

#include <Metal/Metal.h>
#include <QuartzCore/CAMetalLayer.h>
#include <image.h>
#include <string>
#include <chrono>

static void quit(GLFWwindow *window, int key, int scancode, int action, int mods)
{
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
        glfwSetWindowShouldClose(window, GLFW_TRUE);
    }
}

struct TickTok
{
    using clock = std::chrono::high_resolution_clock;
    using tp = clock::time_point;
    tp point;
    
    TickTok() {
        point = clock::now();
    }
    
    void tok(const char* str) {
        auto last = clock::now();
        auto timeElapsed = std::chrono::duration_cast<std::chrono::microseconds>(last - point);
        auto elpased = static_cast<float>(timeElapsed.count() / 1000.0);
        point = last;
        
        NSLog(@"[%s] %f ms", str, elpased);
    }
};

int main(void)
{
    const id<MTLDevice> gpu = MTLCreateSystemDefaultDevice();
    const id<MTLCommandQueue> queue = [gpu newCommandQueue];
    CAMetalLayer *swapchain = [CAMetalLayer layer];
    swapchain.device = gpu;
    swapchain.opaque = YES;

    glfwInit();
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    GLFWwindow *window = glfwCreateWindow(640*3, 480*3, "GLFW Metal", NULL, NULL);
    NSWindow *nswindow = glfwGetCocoaWindow(window);
    nswindow.contentView.layer = swapchain;
    nswindow.contentView.wantsLayer = YES;

    glfwSetKeyCallback(window, quit);
    MTLClearColor color = MTLClearColorMake(0, 0, 0, 1);

    TickTok tick;
    
    auto madoka = el::ImageData::load("../../madoka.jpg");
    assert(madoka != nullptr);

    tick.tok("image load");
    
    auto texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                      width:madoka->width
                                                                     height:madoka->height
                                                                  mipmapped:NO];
    
    tick.tok("texture create");
    
    const uint32_t bytesPerRow = 4 * madoka->width;
    MTLRegion region = MTLRegionMake2D(0, 0, madoka->width, madoka->height);
    id<MTLTexture> texture = [gpu newTextureWithDescriptor:texDesc];
    [texture replaceRegion:region
               mipmapLevel:0
                 withBytes:madoka->stream.data()
               bytesPerRow:bytesPerRow];
    
    tick.tok("upload texture");
    
    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();

        @autoreleasepool {
            color.red = (color.red > 1.0) ? 0 : color.red + 0.01;

            id<CAMetalDrawable> surface = [swapchain nextDrawable];

            MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor renderPassDescriptor];
            pass.colorAttachments[0].clearColor = color;
            pass.colorAttachments[0].loadAction  = MTLLoadActionClear;
            pass.colorAttachments[0].storeAction = MTLStoreActionStore;
            pass.colorAttachments[0].texture = surface.texture;

            id<MTLCommandBuffer> buffer = [queue commandBuffer];
            id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:pass];
            [encoder endEncoding];
            [buffer presentDrawable:surface];
            [buffer commit];
        }
    }

    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}
