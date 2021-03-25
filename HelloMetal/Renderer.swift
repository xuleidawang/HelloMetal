//
//  Renderer.swift
//  HelloMetal
//
//  Created by LEI XU on 3/24/21.
//

import Metal
import MetalKit

class Renderer : NSObject, MTKViewDelegate{
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let pipelineState: MTLRenderPipelineState
    let vertexBuffer: MTLBuffer
    
    // This is the initializer for the Renderer class.
    // We will need access to the mtkView later, so add it as a parameter here.
    init?(mtkView:MTKView)
    {
        device = mtkView.device!
        
        commandQueue = device.makeCommandQueue()!
        
        // Create the Render Pipeline
        do{
            pipelineState = try Renderer.buildRenderPipelineWith(device: device, metalKitView: mtkView)
        }catch{
            print("Unable to compile render pipeline state: \(error)")
            return nil
        }
        
        // Create our vertex data
        let vertices = [Vertex(color: [1, 0, 0, 1], pos: [-1, -1]),
                    Vertex(color: [0, 1, 0, 1], pos: [0, 1]),
                    Vertex(color: [0, 0, 1, 1], pos: [1, -1])]
        
        // Copy vertex to MTLBuffer
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])!
        
    }
    
    // mtkView will automatically call this function
    // whenever it wants new content to be rendered.
    func draw(in view: MTKView)
    {
        // Get an available command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        
        // Get the default MTLRenderPassDescriptor from the MTKView argument
        guard  let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        // Change default settings. Change clear color from black to red
        //renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1)
        
        // Compile renderPassDescriptor to a MTLRenderCommandEncoder
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        // Set up render commands to encode
        // We tell it what render pipeline to use
        renderEncoder.setRenderPipelineState(pipelineState)
        // What vertex buffer data to use
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // What to draw
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        // This finialize the encoding of drawing commands.
        renderEncoder.endEncoding()
        
        // Tell Metal to send the rendering result to the MTKView when rendering completes
        commandBuffer.present(view.currentDrawable!)
        
        // Finally, send the encoded command buffer to the GPU
        commandBuffer.commit()
    }
    
    // mtkView will automatically call this function
    // whenever the size of the view changes.
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    // Create custom rendering pipeline, which loads shaders using 'device', and outputs to the format of 'metalKitView'
    class func buildRenderPipelineWith(device: MTLDevice, metalKitView: MTKView) throws ->MTLRenderPipelineState{
        // Create a new pipeline descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        // Set up shaders in the pipeline
        let library = device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentShader")
        
        // Setup the output pixel format to match the pixel format of the metal kit view
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        
        // Compile the configured pipeline descriptor to a pipeline state object
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}
