//
//  QRCodeScanViewController.m
//  demo
//
//  Created by pennyli on 2018/7/31.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "QRCodeScanViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface QRCodeScanViewController () <AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *layer;
@property (nonatomic, copy) void (^completedBlock)(NSString *);
@end

@implementation QRCodeScanViewController

- (instancetype)initWithScanCompletedBlock:(void (^)(NSString *))completedBlock
{
	if (self = [super initWithNibName: nil bundle: nil]) {
		self.completedBlock = completedBlock;
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: @"Back" style: UIBarButtonItemStyleDone target: self action: @selector(dismiss:)];
	[self setupScanDevice];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupScanDevice
{
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType: AVMediaTypeVideo];
	AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice: device error: nil];
	AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
	[output setMetadataObjectsDelegate: self queue: dispatch_get_main_queue()];
	output.rectOfInterest = CGRectMake(0.05, .2, .7, .6);
	
	_session = [[AVCaptureSession alloc] init];
	[_session setSessionPreset: AVCaptureSessionPresetHigh];
	[_session addInput: input];
	[_session addOutput: output];
	
	output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
	_layer = [AVCaptureVideoPreviewLayer layerWithSession: _session];
	_layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	_layer.frame = self.view.layer.bounds;
	
	[self.view.layer insertSublayer: _layer atIndex: 0];
	
	[_session startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray<AVMetadataMachineReadableCodeObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
	if (metadataObjects.count == 0) return;
	
	[self.session stopRunning];
	NSString *result = [metadataObjects.firstObject stringValue];
	__weak typeof(self) weak_self = self;
	[self dismissViewControllerAnimated: NO completion:^{
		if (weak_self.completedBlock) {
			weak_self.completedBlock(result);
		}
	}];
}

- (void)dismiss:(id)sender
{
	[self dismissViewControllerAnimated: YES completion: NULL];
}

@end
