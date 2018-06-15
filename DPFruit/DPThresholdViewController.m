//
//  DPThresholdViewController.m
//  DPFruit
//
//  Created by caochunyuan on 2018/2/23.
//  Copyright © 2018年 dress. All rights reserved.
//

#import "DPThresholdViewController.h"
#import "DPFruit-Swift.h"
#import "MaskView.h"

float DETECTION_CONFIDENCE[7] = {0.8, 0.9, 0.55, 0.65, 0.65, 0.85, 1.01};

@interface DPThresholdViewController () <RangeSeekSliderDelegate>

@property (weak, nonatomic) IBOutlet RangeSeekSlider *personSlider;
@property (weak, nonatomic) IBOutlet RangeSeekSlider *catSlider;
@property (weak, nonatomic) IBOutlet RangeSeekSlider *dogSlider;
@property (weak, nonatomic) IBOutlet RangeSeekSlider *tableSlider;
@property (weak, nonatomic) IBOutlet RangeSeekSlider *faceSlider;

@end

@implementation DPThresholdViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.personSlider.delegate = self;
    self.catSlider.delegate = self;
    self.dogSlider.delegate = self;
    self.faceSlider.delegate = self;
    self.tableSlider.delegate = self;
    NSArray *confidenceArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"DETECTION_CONFIDENCE"];
    if (confidenceArray) {
        self.personSlider.selectedMinValue = [confidenceArray[1] floatValue];
        self.catSlider.selectedMinValue = [confidenceArray[2] floatValue];
        self.dogSlider.selectedMinValue = [confidenceArray[3] floatValue];
        self.tableSlider.selectedMinValue = [confidenceArray[4] floatValue];
        self.faceSlider.selectedMinValue = [confidenceArray[5] floatValue];
    } else {
        self.personSlider.selectedMinValue = DETECTION_CONFIDENCE[1];
        self.catSlider.selectedMinValue = DETECTION_CONFIDENCE[2];
        self.dogSlider.selectedMinValue = DETECTION_CONFIDENCE[3];
        self.tableSlider.selectedMinValue = DETECTION_CONFIDENCE[4];
        self.faceSlider.selectedMinValue = DETECTION_CONFIDENCE[5];
    }
}

-(void)rangeSeekSlider:(RangeSeekSlider *)slider didChange:(CGFloat)minValue maxValue:(CGFloat)maxValue {
    
}

-(NSString *)rangeSeekSlider:(RangeSeekSlider *)slider stringForMinValue:(CGFloat)minValue {
    return [NSString stringWithFormat:@"%.2f",minValue];
}

- (NSString *)rangeSeekSlider:(RangeSeekSlider *)slider stringForMaxValue:(CGFloat)stringForMaxValue {
    return [NSString stringWithFormat:@"%.2f",stringForMaxValue];
}

- (void)didStartTouchesIn:(RangeSeekSlider *)slider {
    
}

- (void)didEndTouchesIn:(RangeSeekSlider *)slider {
    DETECTION_CONFIDENCE[0] = 0.8;
    DETECTION_CONFIDENCE[1] = self.personSlider.selectedMinValue;
    DETECTION_CONFIDENCE[2] = self.catSlider.selectedMinValue;
    DETECTION_CONFIDENCE[3] = self.dogSlider.selectedMinValue;
    DETECTION_CONFIDENCE[4] = self.tableSlider.selectedMinValue;
    DETECTION_CONFIDENCE[5] = self.faceSlider.selectedMinValue;
    DETECTION_CONFIDENCE[6] = 1.01;

    NSArray *confidenceArray = [NSArray arrayWithObjects:[NSNumber numberWithFloat:DETECTION_CONFIDENCE[0]],[NSNumber numberWithFloat:DETECTION_CONFIDENCE[1]],[NSNumber numberWithFloat:DETECTION_CONFIDENCE[2]],[NSNumber numberWithFloat:DETECTION_CONFIDENCE[3]] ,[NSNumber numberWithFloat:DETECTION_CONFIDENCE[4]],[NSNumber numberWithFloat:DETECTION_CONFIDENCE[5]],[NSNumber numberWithFloat:DETECTION_CONFIDENCE[6]],nil];
    [[NSUserDefaults standardUserDefaults] setObject:confidenceArray forKey:@"DETECTION_CONFIDENCE"];
    MaskView *maskView = [[MaskView alloc] init];
    [maskView reset:DETECTION_CONFIDENCE];
}
- (IBAction)backToForword:(id)sender {
     [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showCameraCapture"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    self.personSlider.delegate = nil;
    self.catSlider.delegate = nil;
    self.dogSlider.delegate = nil;
    self.faceSlider.delegate = nil;
    self.tableSlider.delegate = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
