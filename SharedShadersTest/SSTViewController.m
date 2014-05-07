//
//  SSTViewController.m
//  SharedShadersTest
//
//  Created by Vladislav Gubarev on 07/05/14.
//  Copyright (c) 2014 developer. All rights reserved.
//

#import "SSTViewController.h"

@interface SSTViewController ()

@end

@implementation SSTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}



- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!context || ![EAGLContext setCurrentContext:context]) {
        NSLog(@"!!! EAGLContext");
        return;
    }
    
    [_canvasView initializeWithContext:context];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
