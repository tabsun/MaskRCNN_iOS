//
//  Detect_obj.h
//  TestCoreMLModel
//
//  Created by caochunyuan on 2017/12/29.
//  Copyright © 2017年 dress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


#import <CoreML/CoreML.h>
#import "DPModelNet.h"
#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/imgcodecs/ios.h>
//#import <opencv2/opencv.hpp>


#include <algorithm>
#include <fstream>
#include <iostream>
#include <utility>
#include <vector>
#include <cmath>
#include <cfloat>

// Publicly used structs
struct ROI{
    float val[4];
};
struct Result{
    ROI roi;
    int class_id;
    float score;
};
struct OneMaskObject{
    //ROI bbox;
    float y1, x1, y2, x2;
    cv::Mat mask;
    int class_id;
    float score;
};

////////////////////////////////////////////////////////////////////////
//  MaskRcnn
////////////////////////////////////////////////////////////////////////
class MaskRcnn
{
public:
    MaskRcnn();
    ~MaskRcnn();
    
    float               calc_scale(int h, int w);
    ROI                 calc_window(int h, int w);
    int                 convert_mask(MLMultiArray *masks, std::vector<int> class_id,
                                     std::vector<cv::Mat> &masks_vec,
                                     std::vector<bool> &valid_masks);
    int                 convert_probs_and_deltas(MLMultiArray *probs, MLMultiArray *deltas,
                                                 std::vector<float> &scores,
                                                 std::vector<int> &class_ids,
                                                 std::vector<ROI> &boxes);
    
    std::vector<OneMaskObject>             detect(cv::Mat image);
    MLMultiArray*       preprocess(cv::Mat image, ROI window);
    
    int                 non_max_suppression(std::vector<Result> samples, float nms_thresh,
                                            int max_num,
                                            std::vector<Result> &all);
    ROI                 apply_box_delta(std::vector<float> box,
                                        std::vector<float> delta,
                                        float* bbox_std_dev, float image_shape_w, float image_shape_h);
    ROI                 apply_box_delta(ROI box, ROI delta,
                                        float* bbox_std_dev, float image_shape_w, float image_shape_h);
    // Anchor generation.
    std::vector<ROI>    generate_anchors(int scale, std::vector<float> &ratios,
                                         cv::Size shape, int feature_stride, int anchor_stride);
    std::vector<ROI>    generate_pyramid_anchors(int* scales_ptr, float* ratios_ptr,
                                                 std::vector<cv::Size> &feature_shapes,
                                                 int* feature_strides_ptr,
                                                 int anchor_stride);
    std::vector<ROI>    generate_pyramid_anchors();
    // Video Strategy.
    std::vector<Result>     update_from_last_detections();
    std::pair<ROI,cv::Mat>  update_from_mask(ROI &bbox, cv::Mat &mask);
    // Detection Layer
    std::vector<Result> refine_detections(std::vector<ROI> &rois, std::vector<float> &probs,
                                          std::vector<int> &class_ids, std::vector<ROI> &deltas,
                                          const ROI window);
    // Proposal Layer.
    std::vector<ROI>    proposal_layer(std::vector<MLMultiArray *> &ml_probs,
                                       std::vector<MLMultiArray *> &ml_bboxes);
    
    // ROI Align Layer
    std::vector<cv::Mat>               crop_and_resize(std::vector<cv::Mat> &fm, ROI box,
                                                       cv::Size crop_size, bool is_normalized);
    std::vector<std::vector<cv::Mat>>  roi_align(std::vector<std::vector<cv::Mat>> &feature_maps,
                                                 cv::Size pool_shape,
                                                 std::vector<ROI> &boxes,
                                                 bool is_normalized);
    std::vector<cv::Mat>               crop_and_resize(MLMultiArray *fm, ROI box,
                                                       cv::Size crop_size, bool is_normalized);
    std::vector<std::vector<cv::Mat>>  roi_align(std::vector<MLMultiArray *> &feature_maps,
                                                 cv::Size pool_shape,
                                                 std::vector<ROI> &boxes,
                                                 bool is_normalized);
    void                                reset(float *minConfidence);
    
private:
    // self variables.
    // Some parameters controled by MACROs
    int   MIN_OBJECT_SIZE = 16;
    int   CLASS_NUM = 7;
    float BBOX_STD_DEV[4] = {0.1, 0.1, 0.2, 0.2};
    float IMAGE_SHAPE_W = 320;
    float IMAGE_SHAPE_H = 320;
    // background / person / cat / dog / table / face / others
    float DETECTION_MIN_CONFIDENCE[7] = {0.8, 0.9, 0.55, 0.65, 0.65, 0.85, 1.01};
    float DETECTION_NMS_THRESHOLD = 0.3;
    float DETECTION_MAX_INSTANCES = 10;
    // ANCHOR CONFIG
    int   RPN_ANCHOR_SCALES[5] = {10, 20, 40, 80, 160}; // ;{32, 64, 128, 256, 512}
    float RPN_ANCHOR_RATIOS[3] = {0.5, 1, 2};
    int   BACKBONE_STRIDES[5]  = {4, 8, 16, 32, 64};
    int   RPN_ANCHOR_STRIDE = 1;
    float RPN_BBOX_STD_DEV[4] = {0.1, 0.1, 0.2, 0.2};
    float RPN_NMS_THRESHOLD = 0.7;
    int   POST_NMS_ROIS_INFERENCE = 30;
    
    // Video strategy.
    int   FRAME_COUNT = 0;
    int   DETECTION_FRAME_STEP = 1;
    std::vector<Result> LAST_FRAME_DETECTIONS;
    
    std::vector<cv::Size> BACKBONE_SHAPES;
    std::vector<ROI> M_ANCHORS;
};

////////////////////////////////////////////////
// Depth Detector
////////////////////////////////////////////////
typedef struct BN_PARAM{
    float beta, scale, mean;
}BN_PARAM;
typedef std::vector<BN_PARAM> BN_PARAMS;
class DepthDetector{
public:
    DepthDetector();
    ~DepthDetector();
    
    cv::Mat                 preprocess(cv::Mat image);
    BN_PARAMS               parse_bn_param(std::string file_path);
    double                  bn_and_relu(double x, BN_PARAM param);
    MLMultiArray*           ibr(std::vector<MLMultiArray*> &tensors, BN_PARAMS params);
    std::vector<cv::Mat>    detect(cv::Mat image);
private:
    cv::Size        m_input_size = cv::Size(320, 256);;
    BN_PARAMS       m_bn_params_1,m_bn_params_2,m_bn_params_3,m_bn_params_4;
};
////////////////////////////////////////////////
// Output for chunyuan
////////////////////////////////////////////////


@interface Detect_obj : NSObject

+ (Detect_obj *)detectOBJ;
- (void)reset:(float *)detectionMinConfidence;
- (std::vector<OneMaskObject>)         testDetect:(cv::Mat)image;
- (std::vector<cv::Mat>)               testDepthDetect:(cv::Mat)image;
@end
