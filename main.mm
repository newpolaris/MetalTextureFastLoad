#define GLFW_INCLUDE_NONE
#define GLFW_EXPOSE_NATIVE_COCOA
#include <GLFW/glfw3.h>
#include <GLFW/glfw3native.h>

#include <Metal/Metal.h>
#include <QuartzCore/CAMetalLayer.h>
#include <image.h>
#include <string>
#include <chrono>

const char vertexShaderSrc[] = R"""(
#include <metal_stdlib>
using namespace metal;

typedef struct
{
    packed_float3 position;
    packed_float2 texcoord;
} vertex_t;

typedef struct
{
    float4 clipSpacePosition [[position]];
    float2 textureCoordinate;
} RasterizerData;

vertex RasterizerData main0(
                            const device vertex_t* vertexArray [[buffer(0)]],
                            unsigned int vID[[vertex_id]])
{
    RasterizerData data;
    data.clipSpacePosition = float4(vertexArray[vID].position, 1.0);
    data.textureCoordinate = vertexArray[vID].texcoord;
    return data;
}
)""";
    
const char fragmentShaderSrc[] = R"""(
#include <metal_stdlib>
using namespace metal;

typedef struct
{
    float4 clipSpacePosition [[position]];
    float2 textureCoordinate;
} RasterizerData;

fragment half4 main0(
                     RasterizerData in [[stage_in]],
                     texture2d<half> colorTexture [[texture(0)]])
{
    constexpr sampler textureSampler (mag_filter::nearest,
                                      min_filter::nearest);
    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    // We return the color of the texture
    return colorSample;
}
)""";
    
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
        tic();
    }
    
    void tic() {
        point = clock::now();
    }
    
    void tock(const char* str) {
        auto last = clock::now();
        auto timeElapsed = std::chrono::duration_cast<std::chrono::microseconds>(last - point);
        auto elpased = static_cast<float>(timeElapsed.count() / 1000.0);
        point = last;
        
        NSLog(@"[%s] %f ms", str, elpased);
    }
};

id<MTLFunction> createFunction(id<MTLDevice> gpu, const char* source)
{
    NSString* objcSource = [NSString stringWithCString:source
                                              encoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id<MTLLibrary> library = [gpu newLibraryWithSource:objcSource options:nil error:&error];
    id<MTLFunction> function = [library newFunctionWithName:@"main0"];
    [library release];
    return function;
}
    
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
    
    el::ImageDataPtr miku[2];
    miku[0] = el::ImageData::load("../../miku.jpg");
    miku[1] = el::ImageData::load("../../miku.jpg");
    assert(miku[0] != nullptr);
    assert(miku[1] != nullptr);
    
    tick.tock("image load x2");
    
    id<MTLFunction> vertexFunction = createFunction(gpu, vertexShaderSrc);
    id<MTLFunction> fragmentFunction = createFunction(gpu, fragmentShaderSrc);
 
    NSError* error = nil;

    auto pipelineDesc = [MTLRenderPipelineDescriptor new];
    pipelineDesc.vertexFunction = vertexFunction;
    pipelineDesc.fragmentFunction = fragmentFunction;
    pipelineDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    id<MTLRenderPipelineState> pipelineState = [gpu newRenderPipelineStateWithDescriptor:pipelineDesc error:&error];
    
    [pipelineDesc release];
    
    assert(pipelineState != nil);
    
    tick.tock("pipeline create");
    
    const auto width = miku[0]->width;
    const auto height = miku[0]->height;
    const uint32_t bytesPerRow = miku[0]->getBytesPerRow();
    
    auto texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                      width:width
                                                                     height:height
                                                                  mipmapped:NO];
    

    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    id<MTLTexture> texture = [gpu newTextureWithDescriptor:texDesc];
    
    tick.tock("texture create");
    
    uint32_t frame = 0;
    
    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();

        @autoreleasepool {
            
            // trying to test aysnc texture load ?
            if (true) {
                tick.tic();
                
                auto data = miku[frame % 2]->data();

                [texture replaceRegion:region
                           mipmapLevel:0
                             withBytes:data
                           bytesPerRow:bytesPerRow];
                
                tick.tock("upload texture");
                frame++;
            }
            
            color.red = (color.red > 1.0) ? 0 : color.red + 0.01;

            id<CAMetalDrawable> surface = [swapchain nextDrawable];

            MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor renderPassDescriptor];
            pass.colorAttachments[0].clearColor = color;
            pass.colorAttachments[0].loadAction  = MTLLoadActionClear;
            pass.colorAttachments[0].storeAction = MTLStoreActionStore;
            pass.colorAttachments[0].texture = surface.texture;

            id<MTLCommandBuffer> buffer = [queue commandBuffer];
            id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:pass];
            [encoder setRenderPipelineState:pipelineState];
            [encoder endEncoding];
            [buffer presentDrawable:surface];
            [buffer commit];
            [buffer waitUntilCompleted];
        }
    }

    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}
