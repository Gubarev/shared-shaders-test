//
//  SSTCanvasView.m
//  SharedShadersTest
//
//  Created by Vladislav Gubarev on 07/05/14.
//  Copyright (c) 2014 developer. All rights reserved.
//

#import "SSTCanvasView.h"
#import <OpenGLES/EAGL.h>



#define SST_USE_ANOTHER_CONTEXT 1



const static GLchar simpleVShSrc[] =
"#extension GL_EXT_separate_shader_objects : enable\n"
"layout(location = 0) attribute vec4 vPosition;\n"
"void main() {\n"
"    gl_Position = vPosition;\n"
"}\n";



const static GLchar simpleFShSrc[] =
"void main() {\n"
"    gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);\n"
"}\n";



@implementation SSTCanvasView

{
    EAGLContext *_context;
    EAGLContext *_anotherContext;
    
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    
    GLuint _vertexShader;
    GLuint _fragmentShader;
    GLuint _pipeline;
    
    CGSize _frameBufferSize;
}



- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}



+ (Class)layerClass {
    return [CAEAGLLayer class];
}



- (void)initializeWithContext:(EAGLContext *)context {
    // For retina.
    CGFloat scale = [[UIScreen mainScreen] scale];
    self.contentScaleFactor = scale;
    
    // Canvas size.
    _frameBufferSize.height = scale * self.bounds.size.height;
    _frameBufferSize.width  = scale * self.bounds.size.width;
    
    // EAGL context.
    CAEAGLLayer* caeagllayer = (CAEAGLLayer *)self.layer;
    caeagllayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking,
                                      kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    _context = context;
    
    // Framebuffer and Renderbuffer.
    {
        glGenFramebuffers (1, &_frameBuffer);
        glGenRenderbuffers(1, &_renderBuffer);
        
        glBindFramebuffer (GL_FRAMEBUFFER,  _frameBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
        
        [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id<EAGLDrawable>)self.layer];
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
        GLenum st = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (GL_FRAMEBUFFER_COMPLETE != st) {
            NSLog(@"CanvasView: Failed to make complete framebuffer !! %x", st);
            glDeleteFramebuffers (1, &_frameBuffer);
            glDeleteRenderbuffers(1, &_renderBuffer);
            return;
        }
    }
    
    // Another context in same shared group.
#if SST_USE_ANOTHER_CONTEXT
    glFlush();
    _anotherContext = [[EAGLContext alloc] initWithAPI:[_context API] sharegroup:[_context sharegroup]];
#else
    _anotherContext = _context;
#endif
    
    // Shaders, pipeline in another context.
    {
        [EAGLContext setCurrentContext:_anotherContext];
        
        
        // Vertex shader.
        {
            const GLchar *pSrc[] = {simpleVShSrc};
            _vertexShader = glCreateShaderProgramvEXT(GL_VERTEX_SHADER, 1, pSrc);
            glProgramParameteriEXT(_vertexShader, GL_PROGRAM_SEPARABLE_EXT, GL_TRUE);
        }
        
        // Fragment shader.
        {
            const GLchar *pSrc[] = {simpleFShSrc};
            _fragmentShader = glCreateShaderProgramvEXT(GL_FRAGMENT_SHADER, 1, pSrc);
            glProgramParameteriEXT(_fragmentShader, GL_PROGRAM_SEPARABLE_EXT, GL_TRUE);
        }
        
        // Pipeline and attributes.
        {
            glGenProgramPipelinesEXT(1, &_pipeline);
            glBindProgramPipelineEXT(_pipeline);
            glEnableVertexAttribArray(0);
        }
        
        
        [EAGLContext setCurrentContext:_context];
    }
    
    [self draw];
}



- (void)draw {
    // Bind and clear framebuffer.
    glBindFramebuffer (GL_FRAMEBUFFER,  _frameBuffer);
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Set viewport.
    glViewport(0, 0, _frameBufferSize.width, _frameBufferSize.height);
    
    // Setup pipeline and shaders.
    glBindProgramPipelineEXT(_pipeline);
    glUseProgramStagesEXT(_pipeline, GL_VERTEX_SHADER_BIT_EXT,   _vertexShader);
    glUseProgramStagesEXT(_pipeline, GL_FRAGMENT_SHADER_BIT_EXT, _fragmentShader);
    
    // Setup vertex.
    GLfloat vertex[] = {
       -0.5,  0.5,
        0.5,  0.5,
       -0.5, -0.5,
        0.5, -0.5
    };
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, 0, 2 * sizeof(GLfloat), vertex);
    
    // Render.
    glDisable(GL_BLEND);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // Present.
    [self present];
    glFlush();
}



- (void)present {
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
