//
//  Detect_obj.m
//  TestCoreMLModel
//
//  Created by caochunyuan on 2017/12/29.
//  Copyright © 2017年 dress. All rights reserved.
//

#import "Detect_obj.h"

////////////////////////////////////////////////////////
// MaskRcnn
////////////////////////////////////////////////////////

// Support functions
MLMultiArray* MatToMLMultiArray(cv::Mat image)
{
    int w = image.cols, h = image.rows, c = image.channels();
    NSArray *shape = @[[NSNumber numberWithInt:c],
                       [NSNumber numberWithInt:h],
                       [NSNumber numberWithInt:w]];
    MLMultiArray *array = [[MLMultiArray alloc] initWithShape:shape dataType:MLMultiArrayDataTypeDouble error:nil];
    
    ;
    double *dst = (double*)array.dataPointer;
    for(int ci=0; ci<c; ci++)
    {
        for(int y=0; y<h; y++)
        {
            for(int x=0; x<w; x++)
            {
                float* src = image.ptr<float>(y);
                dst[0] = double(src[x*c + ci]);
                dst ++;
            }
        }
    }
    return array;
}
MLMultiArray* MatToMLMultiArray(std::vector<cv::Mat> &images, int start, int end)
{
    int n = end - start + 1, w = images[0].cols, h = images[0].rows, c = images[0].channels();
    NSArray *shape = @[@1,
                       [NSNumber numberWithInt:n],
                       [NSNumber numberWithInt:c],
                       [NSNumber numberWithInt:h],
                       [NSNumber numberWithInt:w]];
    MLMultiArray *array = [[MLMultiArray alloc] initWithShape:shape dataType:MLMultiArrayDataTypeDouble error:nil];
    
    ;
    double *dst = (double*)array.dataPointer;
    for(int ni=0; ni<n; ni++)
    {
        cv::Mat image = images[ni];
        assert(image.cols == w and image.rows == h);
        for(int ci=0; ci<c; ci++)
        {
            for(int y=0; y<h; y++)
            {
                for(int x=0; x<w; x++)
                {
                    float* src = image.ptr<float>(y);
                    dst[0] = double(src[x*c + ci]);
                    dst ++;
                }
            }
        }
    }
    return array;
}
MLMultiArray* FeatureMapsToMLMultiArray(std::vector<std::vector<cv::Mat>> &fmp, cv::Size map_size,
                                        int start, int max_batch_size)
{
    assert(start < fmp.size());
    assert(fmp[0].size() == 64);
    int N = int(fmp.size()) - start < max_batch_size ? (int(fmp.size()) - start) : max_batch_size;
    
    int w = map_size.width, h = map_size.height;
    NSArray *shape = @[@1, [NSNumber numberWithInt:max_batch_size],
                       @256, [NSNumber numberWithInt:h], [NSNumber numberWithInt:w]];
    MLMultiArray *array = [[MLMultiArray alloc] initWithShape:shape dataType:MLMultiArrayDataTypeDouble error:nil];
    
    double *qtr = (double*)array.dataPointer;
    for(int box_id=start; box_id<start+N && box_id<fmp.size(); box_id++)
    {
        for(int depth=0; depth<256; depth++)
        {
            cv::Mat cur_mat = fmp[box_id][depth/4];
            for(int i=0; i<h; i++)
            {
                float *ptr = cur_mat.ptr<float>(i) + depth%4;
                for(int j=0; j<w; j++)
                {
                    // Tabsun' DEBUG flag !!!!
                    *qtr++ = *ptr;
                    ptr += 4;
                }
            }
        }
    }
    return array;
}

std::vector<cv::Mat> MLMultiArrayToFeatureMaps(MLMultiArray* array)
{
    NSArray *shape = array.shape;
    int chn = [shape[0] intValue];
    int h = [shape[1] intValue];
    int w = [shape[2] intValue];
    
    std::vector<cv::Mat> feature_maps;
    feature_maps.reserve(64);
    double *qtr = (double*)array.dataPointer;
    
    cv::Mat feature_map(h, w, CV_64FC4);
    int step = h*w;
    for(int i=0; i<chn/4; i++)
    {
        double *qtr_0 = qtr + i*4*step;
        double *qtr_1 = qtr_0 + step;
        double *qtr_2 = qtr_1 + step;
        double *qtr_3 = qtr_2 + step;
        for(int j=0; j<h; j++)
        {
            double *ptr = feature_map.ptr<double>(j);
            for(int k=0; k<w; k++)
            {
                ptr[k*4] = qtr_0[0];
                ptr[k*4+1] = qtr_1[0];
                ptr[k*4+2] = qtr_2[0];
                ptr[k*4+3] = qtr_3[0];
                qtr_0++; qtr_1++; qtr_2++; qtr_3++;
            }
        }
        feature_maps.push_back(feature_map.clone());
    }
    return feature_maps;
}
int add_one_mask(cv::Mat &image, OneMaskObject obj)
{
    std::vector<cv::Scalar> colors;
    colors.push_back(cv::Scalar(0, 255, 0));
    colors.push_back(cv::Scalar(255, 0, 0));
    colors.push_back(cv::Scalar(0, 0, 255));
    colors.push_back(cv::Scalar(255, 255, 0));
    colors.push_back(cv::Scalar(0, 255, 255));
    colors.push_back(cv::Scalar(255, 0, 255));
    colors.push_back(cv::Scalar(128, 0, 0));
    colors.push_back(cv::Scalar(0, 128, 0));
    colors.push_back(cv::Scalar(0, 0, 128));
    colors.push_back(cv::Scalar(128, 128, 0));
    colors.push_back(cv::Scalar(0, 128, 128));
    colors.push_back(cv::Scalar(128, 0, 128));
    
    int color_id = rand() * int(colors.size()) / RAND_MAX;
    cv::Scalar color = colors[color_id];
    int offset_x = obj.x1;
    int offset_y = obj.y1;
    cv::Mat mask = obj.mask;
    for(int j=0; j<mask.rows; j++)
    {
        int temp_y = std::max(std::min(image.rows, offset_y+j), 0);
        uchar* p = image.ptr<uchar>(temp_y);
        double* pm = mask.ptr<double>(j);
        for(int i=0; i<mask.cols; i++)
        {
            if(pm[i] > 0.5){
                int temp_x = std::max(std::min(image.cols, offset_x+i), 0);
                
                p[temp_x*3+0] = (color.val[0] + p[temp_x*3+0])/2.;
                p[temp_x*3+1] = (color.val[1] + p[temp_x*3+1])/2.;
                p[temp_x*3+2] = (color.val[2] + p[temp_x*3+2])/2.;
            }
        }
    }
    return 0;
}

MaskRcnn::MaskRcnn()
{
    // Config env.
    for(int i=0; i<5; i++)
    {
        BACKBONE_SHAPES.push_back(cv::Size(IMAGE_SHAPE_W/BACKBONE_STRIDES[i],
                                           IMAGE_SHAPE_H/BACKBONE_STRIDES[i]));
    }
    // Generate anchors.
    M_ANCHORS = generate_pyramid_anchors();
}

MaskRcnn::~MaskRcnn()
{}
void MaskRcnn::reset(float *minConfidence){
//    FRAME_COUNT = 0;
//    LAST_FRAME_DETECTIONS.clear();
    
    //float temp_confidence[7] = {};
    memcpy((float*)DETECTION_MIN_CONFIDENCE, (float*)minConfidence, sizeof(float)*7);
}

std::vector<OneMaskObject> MaskRcnn::detect(cv::Mat image)
{
    double t_start = cv::getTickCount();
    // Preprocess.
    ROI window = calc_window(image.rows, image.cols);
    float scale = calc_scale(image.rows, image.cols);
    MLMultiArray* input_array = preprocess(image, window);
    
    if([input_array.shape[0] intValue] != 3 ||
       [input_array.shape[1] intValue] != IMAGE_SHAPE_H ||
       [input_array.shape[2] intValue] != IMAGE_SHAPE_W)
        return std::vector<OneMaskObject>();
//    double t = cv::getTickCount();
//    std::cout << "Preprocess time : " << (t-t_start)/cv::getTickFrequency()*1000.0 << "ms" << std::endl;
    
    // First model to calculate P2~P5 feature maps and region proposals.
//    double t = cv::getTickCount();
    mask_rpn *maskrpnModel = [DPModelNet mask_rpn];
    mask_rpnOutput *output = [maskrpnModel predictionFromInput1:input_array error:nil];
//    t = cv::getTickCount() - t;
//    std::cout << "First model time : " << t/cv::getTickFrequency()*1000.0 << "ms" << std::endl;
    
    // Get P2~P5 feature maps from outputs.
//    t = cv::getTickCount();
    std::vector<MLMultiArray *> multi_feature_maps;
    if([output.output1.shape[0] intValue] != 256 ||
       [output.output1.shape[1] intValue] !=  80 ||
       [output.output1.shape[2] intValue] !=  80 )
        return std::vector<OneMaskObject>();
    multi_feature_maps.push_back(output.output1);
    if([output.output2.shape[0] intValue] != 256 ||
       [output.output2.shape[1] intValue] !=  40 ||
       [output.output2.shape[2] intValue] !=  40 )
        return std::vector<OneMaskObject>();
    multi_feature_maps.push_back(output.output2);
    if([output.output3.shape[0] intValue] != 256 ||
       [output.output3.shape[1] intValue] !=  20 ||
       [output.output3.shape[2] intValue] !=  20 )
        return std::vector<OneMaskObject>();
    multi_feature_maps.push_back(output.output3);
    if([output.output4.shape[0] intValue] != 256 ||
       [output.output4.shape[1] intValue] !=  10 ||
       [output.output4.shape[2] intValue] !=  10 )
        return std::vector<OneMaskObject>();
    multi_feature_maps.push_back(output.output4);
//    t = cv::getTickCount()-t;
//    std::cout << "Get P2~P5 feature maps time : " << t/cv::getTickFrequency()*1000.0 << "ms" << std::endl;
    
    std::vector<Result> cur_detections;
    if(FRAME_COUNT % DETECTION_FRAME_STEP == 0)
    {
//        t = cv::getTickCount();
        std::vector<MLMultiArray*> prob_outputs, bbox_outputs;
        
        prob_outputs.push_back(output.output5);
        prob_outputs.push_back(output.output7);
        prob_outputs.push_back(output.output9);
        prob_outputs.push_back(output.output11);
        prob_outputs.push_back(output.output13);
        
        bbox_outputs.push_back(output.output6);
        bbox_outputs.push_back(output.output8);
        bbox_outputs.push_back(output.output10);
        bbox_outputs.push_back(output.output12);
        bbox_outputs.push_back(output.output14);
        
//        t = cv::getTickCount() - t;
//        std::cout << "Parse outputs time : " << t/cv::getTickFrequency()*1000.0 << "ms" << std::endl;
        
//        t = cv::getTickCount();
        std::vector<ROI> region_proposals = proposal_layer(prob_outputs, bbox_outputs);
//        t = cv::getTickCount()-t;
//        std::cout << "Proposal time : " << t/cv::getTickFrequency()*1000.0 << "ms" << std::endl;

        // Run roi_align.
        cv::Size POOL_SIZE(7,7);
//        t = cv::getTickCount();
        std::vector<std::vector<cv::Mat>> feature_maps = roi_align(multi_feature_maps, POOL_SIZE, region_proposals, true);
//        t = cv::getTickCount()-t;
//        std::cout << "1st roi_align time with " << region_proposals.size() << ": " << t/cv::getTickFrequency()*1000.0 << "ms" << std::endl;
        
        // Class & Prob model.
        mask_class_box *maskClassBox = [DPModelNet maskClassBox];
        
        std::vector<float> probs;
        std::vector<int>   class_ids;
        std::vector<ROI>   deltas;
        
//        t = cv::getTickCount();
        int start = 0;
        while(start < feature_maps.size())
        {
            // Convert to MLMultiArray for 2nd model's input.
            int max_batch_size = std::min(8, int(feature_maps.size()) - start);
            MLMultiArray *roi_align_output = FeatureMapsToMLMultiArray(feature_maps, POOL_SIZE,
                                                                       start, max_batch_size);
            // Second model run.
            mask_class_boxOutput *boxOutput = [maskClassBox predictionFromInput1:roi_align_output error:nil];
            if(boxOutput.output1.count != max_batch_size*7)
                return std::vector<OneMaskObject>();
            if(boxOutput.output2.count != max_batch_size*7*4)
                return std::vector<OneMaskObject>();
            convert_probs_and_deltas(boxOutput.output1, boxOutput.output2, probs, class_ids, deltas);
            start += max_batch_size;
        }
//        t = cv::getTickCount()-t;
//        std::cout << start << " x rpn time : " << t/cv::getTickFrequency()*1000.0 << "ms" << std::endl;
        // Detection Layer.
//        t = cv::getTickCount();
        cur_detections = refine_detections(region_proposals, probs,
                                                           class_ids, deltas, window);
//        t = cv::getTickCount()-t;
//        std::cout << "Detection Layer time : " << t/cv::getTickFrequency()*1000.0 << "ms" << std::endl;
    }
    else{
        // Enlarge the detection bboxes as current frame detections' bboxes.
        cur_detections = update_from_last_detections();
    }
    // ROI Align Layer for mask generation.
//    t = cv::getTickCount();
    std::vector<ROI> detection_rois;
    for(Result res : cur_detections)
        detection_rois.push_back(res.roi);
    
    cv::Size POOL_SIZE = cv::Size(14, 14);
    std::vector<std::vector<cv::Mat>> feature_maps_14 = roi_align(multi_feature_maps, POOL_SIZE, detection_rois, false);
    
//    t = cv::getTickCount()-t;
//    std::cout << "2nd roi_align time with " << detection_rois.size() << ": " << t/cv::getTickFrequency()*1000.0 << "ms" << std::endl;
    
    // Calculate mask.
    mask_branch_noalign *maskBranch = [DPModelNet maskBranchNoalign];
//    t = cv::getTickCount();
    std::vector<cv::Mat> masks;
    std::vector<bool> valid_masks;
    int start = 0;
    while(start < feature_maps_14.size())
    {
        // Convert to MLMultiArray for 2nd model's input.
        int max_batch_size = std::min(int(feature_maps_14.size()) - start, 4);
        MLMultiArray *roi_align_output = FeatureMapsToMLMultiArray(feature_maps_14, POOL_SIZE,
                                                                   start, max_batch_size);
        // Third model run.
        mask_branch_noalignOutput *boxOutput = [maskBranch predictionFromInput1:roi_align_output error:nil];
        
        std::vector<int> class_ids;
        for(int ite=start; ite<start+max_batch_size; ite++){
            class_ids.push_back(cur_detections[ite].class_id);
        }
        if(boxOutput.output1.count != (7*28*28*max_batch_size))
            return std::vector<OneMaskObject>();
        convert_mask(boxOutput.output1, class_ids, masks, valid_masks);
        start += max_batch_size;
    }
    if(FRAME_COUNT % DETECTION_FRAME_STEP != 0)
    {
        std::vector<float> probs;
        std::vector<int>   class_ids;
        std::vector<ROI>   deltas;
        // Valid Tracking-detections.
        POOL_SIZE = cv::Size(7, 7);
        std::vector<std::vector<cv::Mat>> feature_maps_valid = roi_align(multi_feature_maps, POOL_SIZE, detection_rois, false);
        // Class & Prob model.
        mask_class_box *maskClassBox = [DPModelNet maskClassBox];
        start = 0;
        while(start < feature_maps_valid.size())
        {
            // Convert to MLMultiArray for 2nd model's input.
            int max_batch_size = std::min(8, int(feature_maps_valid.size()) - start);
            MLMultiArray *roi_align_output = FeatureMapsToMLMultiArray(feature_maps_valid, POOL_SIZE,
                                                                       start, max_batch_size);
            // Second model run.
            mask_class_boxOutput *boxOutput = [maskClassBox predictionFromInput1:roi_align_output error:nil];
            convert_probs_and_deltas(boxOutput.output1, boxOutput.output2, probs, class_ids, deltas);
            start += max_batch_size;
        }
        for (int i=0; i<probs.size(); i++) {
            valid_masks[i] = (valid_masks[i] &&
                              (probs[i] > ((float*)DETECTION_MIN_CONFIDENCE)[class_ids[i]]));
        }
    }
    
//    t = cv::getTickCount()-t;
//    std::cout << start << " x Mask model time : " << t/cv::getTickFrequency()*1000.0 << "ms" << std::endl;
    
    std::vector<OneMaskObject> objects;
    for (int i = 0; i < cur_detections.size(); i++) {
        if(!valid_masks[i])
            continue;
        OneMaskObject one_object;
        ROI cur = cur_detections[i].roi;
        cv::Mat mask = masks[i];
        if(FRAME_COUNT % DETECTION_FRAME_STEP != 0)
        {
            std::pair<ROI, cv::Mat> modified_bbox_mask = update_from_mask(cur_detections[i].roi, masks[i]);
            cur = modified_bbox_mask.first;
            mask = modified_bbox_mask.second;
            cur_detections[i].roi = cur;
        }

        one_object.score = cur_detections[i].score;
        one_object.class_id = cur_detections[i].class_id;
        one_object.y1 = (cur.val[0]-window.val[0])/scale;
        one_object.x1 = (cur.val[1]-window.val[1])/scale;
        one_object.y2 = (cur.val[2]-window.val[0])/scale;
        one_object.x2 = (cur.val[3]-window.val[1])/scale;
        
        cv::resize(mask, one_object.mask, cv::Size(one_object.x2-one_object.x1,
                                                       one_object.y2-one_object.y1));
        one_object.mask.convertTo(one_object.mask, CV_64FC1);
        objects.push_back(one_object);
    }
    LAST_FRAME_DETECTIONS = cur_detections;
    FRAME_COUNT ++;
    FRAME_COUNT %= DETECTION_FRAME_STEP;
    
//    double t = cv::getTickCount()-t_start;
//    std::cout << "Mask with face time : " << t/cv::getTickFrequency()*1000.0 << "ms" << std::endl;
    return objects;
}
// Support funcs
float MaskRcnn::calc_scale(int h, int w)
{
    return IMAGE_SHAPE_W * 1.0f / std::max(h, w);
}
ROI MaskRcnn::calc_window(int h, int w)
{
    float scale = IMAGE_SHAPE_W *1.0f / std::max(w,h);
    int dst_w = std::min(IMAGE_SHAPE_W, round(w * scale));
    int dst_h = std::min(IMAGE_SHAPE_H, round(h * scale));
    ROI window;
    int y1 = (IMAGE_SHAPE_H - dst_h)/2;
    int x1 = (IMAGE_SHAPE_W - dst_w)/2;
    window.val[0] = y1;
    window.val[1] = x1;
    window.val[2] = y1 + dst_h;
    window.val[3] = x1 + dst_w;
    return window;
}

MLMultiArray* MaskRcnn::preprocess(cv::Mat image, ROI window)
{
    int w = image.cols;
    int h = image.rows;
    int y1 = window.val[0];
    int x1 = window.val[1];
    int y2 = window.val[2];
    int x2 = window.val[3];
    int dst_w = x2 - x1;
    int dst_h = y2 - y1;
    
    cv::cvtColor(image, image, CV_BGR2RGB);
    
    cv::Mat pad_img = cv::Mat::zeros(IMAGE_SHAPE_W, IMAGE_SHAPE_H, CV_32FC3);
    if(w != dst_w || h != dst_h)
    {
        cv::Mat dst_img(dst_w, dst_h, CV_32FC3);
        cv::resize(image, dst_img, cv::Size(dst_w, dst_h));
        dst_img.copyTo(pad_img(cv::Rect(x1, y1, dst_w, dst_h)));
    }
    else
    {
        image.copyTo(pad_img(cv::Rect(x1, y1, w, h)));
    }
    
    NSArray *shape = @[@3, [NSNumber numberWithInt:IMAGE_SHAPE_H], [NSNumber numberWithInt:IMAGE_SHAPE_W]];
    MLMultiArray *mlArray = [[MLMultiArray alloc] initWithShape:shape dataType:MLMultiArrayDataTypeFloat32 error:nil];
    
    float* qtr = (float*)mlArray.dataPointer;
    std::vector<float> mean_val;
    mean_val.push_back(123.7f);
    mean_val.push_back(116.8f);
    mean_val.push_back(103.9f);
    for(int k=0; k<3; k++)
    {
        float cur_mean = mean_val[k];;
        for(int i=0; i<IMAGE_SHAPE_H; i++)
        {
            float* ptr = pad_img.ptr<float>(i);
            for(int j=0; j<IMAGE_SHAPE_W; j++)
            {
                *qtr++ = ptr[j*3+k] - cur_mean;
            }
        }
    }
    return mlArray;
}


int MaskRcnn::convert_mask(MLMultiArray *masks, std::vector<int> class_ids,
                           std::vector<cv::Mat> &masks_vec,
                           std::vector<bool> &valid_masks)
{
    NSArray *shape = masks.shape;
    int N = [masks.shape[0] intValue];
    if(shape.count == 3)
        N = 1;
    
    int box_step = CLASS_NUM * 28 * 28, chn_step = 28 * 28, count = 0;
    double *mask_ = (double*)masks.dataPointer;
    while(count < N)
    {
        double *cur_ = mask_ + count * box_step + class_ids[count] * chn_step;
        cv::Mat mask(28, 28, CV_32FC1);
        int fg_pt_num = 0;
        for(int i=0; i<28; i++){
            float* ptr = mask.ptr<float>(i);
            cur_ += 28;
            for(int j=0; j<28; j++){
                ptr[j] = cur_[j];
                if(cur_[j] > 0.5)
                    fg_pt_num ++;
            }
        }
        valid_masks.push_back(fg_pt_num * 1.0f / 784 > 0.1);
        masks_vec.push_back(mask);
        count ++;
    }
    return 0;
}
int MaskRcnn::convert_probs_and_deltas(MLMultiArray *probs, MLMultiArray *deltas,
                          std::vector<float> &scores, std::vector<int> &class_ids, std::vector<ROI> &boxes)
{
    int N = [probs.shape[0] intValue];
    NSArray *probs_shape = probs.shape;
    NSArray *deltas_shape = deltas.shape;
    if(probs_shape.count == 1)
        N = 1;
    if(deltas_shape.count == 3)
        assert(N == 1);
    else
        assert(N == [deltas.shape[0] intValue]);
    
    double *prob_ = (double*)probs.dataPointer, *delta_ = (double*)deltas.dataPointer;
    for(int box_id=0; box_id<N; box_id++)
    {
        float max_score = -1000.f;
        int class_id = -1;
        for(int i=0; i<CLASS_NUM; i++)
        {
            float temp = prob_[box_id*CLASS_NUM+i];
            if( temp > max_score)
            {
                max_score = temp;
                class_id = i;
            }
        }
        
        class_ids.push_back(class_id);
        scores.push_back(max_score);
        ROI temp_roi;
        temp_roi.val[0] = delta_[box_id*4*CLASS_NUM + 0*CLASS_NUM + class_id];
        temp_roi.val[1] = delta_[box_id*4*CLASS_NUM + 1*CLASS_NUM + class_id];
        temp_roi.val[2] = delta_[box_id*4*CLASS_NUM + 2*CLASS_NUM + class_id];
        temp_roi.val[3] = delta_[box_id*4*CLASS_NUM + 3*CLASS_NUM + class_id];
        boxes.push_back(temp_roi);
    }
    return 0;
}
inline bool base_on_score_descend(Result &a, Result &b) {return (a.score > b.score);}
inline bool base_on_score_ascend( Result &a, Result &b) {return (a.score < b.score);}
int MaskRcnn::non_max_suppression(std::vector<Result> samples, float nms_thresh, int max_num, std::vector<Result> &all)
{
    if(samples.empty()) return 0;
    
    std::sort(samples.begin(), samples.end(), base_on_score_ascend);
    int count = 0;
    while(samples.size() > 0 and count < max_num)
    {
        // Pick the top one
        //ROI temp = samples[samples.size()-1].roi;
        //std::cout << "when i push: " << temp.val[0] << " " << temp.val[1] << " " << temp.val[2] << " " << temp.val[3] << std::endl;
        
        all.push_back(samples[samples.size()-1]);
        count ++;
        ROI box = samples[samples.size()-1].roi;
        float area = (box.val[2] - box.val[0]) * (box.val[3] - box.val[1]);
        // Remove the top one from samples
        samples.pop_back();
        
        std::vector<Result> temp;
        for(std::vector<Result>::iterator ite=samples.begin(); ite<samples.end(); ite++)
        {
            ROI cur_box = ite->roi;
            // Compute IOU
            float cur_area = (cur_box.val[2] - cur_box.val[0]) * (cur_box.val[3] - cur_box.val[1]);
            float y1 = std::max(box.val[0], cur_box.val[0]);
            float y2 = std::min(box.val[2], cur_box.val[2]);
            float x1 = std::max(box.val[1], cur_box.val[1]);
            float x2 = std::min(box.val[3], cur_box.val[3]);
            float intersection = std::max(x2-x1, 0.f) * std::max(y2-y1, 0.f);
            float unionsection = cur_area + area - intersection;
            float iou = intersection / unionsection;
            
            // Once the rest rois have IOU(>nms_thresh) with box, it will be removed.
            if(iou < nms_thresh)
            {
                temp.push_back(*ite);
            }
        }
        samples = temp;
    }
    return 0;
}
ROI MaskRcnn::apply_box_delta(std::vector<float> box,
                              std::vector<float> delta,
                              float* bbox_std_dev, float image_shape_w, float image_shape_h)
{
    ROI ret_roi;
    
    float height = box[2] - box[0];
    float width =  box[3] - box[1];
    float center_y = box[0] + 0.5*height;
    float center_x = box[1] + 0.5*width;
    //Apply delta
    center_y += delta[0] * height * bbox_std_dev[0];
    center_x += delta[1] * width * bbox_std_dev[1];
    height *= exp(delta[2] * bbox_std_dev[2]);
    width  *= exp(delta[3] * bbox_std_dev[3]);
    //Convert back to y1,x1,y2,x2
    float y1 = (center_y - 0.5 *height);
    float x1 = (center_x - 0.5 *width);
    float y2 = (y1 + height) * image_shape_h;
    float x2 = (x1 + width) * image_shape_w;
    y1 *= image_shape_h;
    x1 *= image_shape_w;
    ret_roi.val[0] = y1;
    ret_roi.val[1] = x1;
    ret_roi.val[2] = y2;
    ret_roi.val[3] = x2;
    return ret_roi;
}

ROI MaskRcnn::apply_box_delta(ROI box, ROI delta,
                              float* bbox_std_dev, float image_shape_w, float image_shape_h)
{
    ROI ret_roi;
    
    float height = box.val[2] - box.val[0];
    float width =  box.val[3] - box.val[1];
    float center_y = box.val[0] + 0.5*height;
    float center_x = box.val[1] + 0.5*width;
    //Apply delta
    center_y += delta.val[0] * height * bbox_std_dev[0];
    center_x += delta.val[1] * width * bbox_std_dev[1];
    height *= exp(delta.val[2] * bbox_std_dev[2]);
    width  *= exp(delta.val[3] * bbox_std_dev[3]);
    //Convert back to y1,x1,y2,x2
    float y1 = (center_y - 0.5 *height);
    float x1 = (center_x - 0.5 *width);
    float y2 = (y1 + height) * image_shape_h;
    float x2 = (x1 + width) * image_shape_w;
    y1 *= image_shape_h;
    x1 *= image_shape_w;
    ret_roi.val[0] = y1;
    ret_roi.val[1] = x1;
    ret_roi.val[2] = y2;
    ret_roi.val[3] = x2;
    return ret_roi;
}
// ENLARGE last frame detections.
std::vector<Result> MaskRcnn::update_from_last_detections()
{
    float scale = 0.2;
    std::vector<Result> cur;
    for( Result res : LAST_FRAME_DETECTIONS)
    {
        float width = res.roi.val[3] - res.roi.val[1];
        float height = res.roi.val[2] - res.roi.val[0];
        if(width < MIN_OBJECT_SIZE || height < MIN_OBJECT_SIZE)
            continue;
        res.roi.val[0] = std::max(0.f, res.roi.val[0] - height*scale); // y1
        res.roi.val[1] = std::max(0.f, res.roi.val[1] - width*scale); // x1
        res.roi.val[2] = std::min(IMAGE_SHAPE_H-1, res.roi.val[2] + height*scale); // y2
        res.roi.val[3] = std::min(IMAGE_SHAPE_W-1, res.roi.val[3] + width*scale); // x2
        cur.push_back(res);
    }
    return cur;
}
std::pair<ROI,cv::Mat> MaskRcnn::update_from_mask(ROI &bbox, cv::Mat &mask)
{
    cv::Mat temp_mask;
    int width = int(round(bbox.val[3] - bbox.val[1]));
    int height = int(round(bbox.val[2] - bbox.val[0]));
    cv::resize(mask, temp_mask, cv::Size(width, height));
    int left = width, right = 0, top = height, bottom = 0;
    for(int i=0; i<height; i++)
    {
        float *ptr = temp_mask.ptr<float>(i);
        for (int j=0; j<width; j++) {
            if(ptr[j] > 0.5)
            {
                left = std::min(j, left);
                right = std::max(j, right);
                top = std::min(i, top);
                bottom = std::max(i, bottom);
            }
        }
    }
    mask = temp_mask(cv::Rect(left, top, right-left, bottom-top));
    bbox.val[2] = bbox.val[0] + bottom;
    bbox.val[3] = bbox.val[1] + right;
    bbox.val[0] += top;
    bbox.val[1] += left;
    
    return std::make_pair(bbox, mask);
}
// DETECTION LAYER
std::vector<Result> MaskRcnn::refine_detections(std::vector<ROI> &rois,
                                                std::vector<float> &probs,
                                                std::vector<int> &class_ids,
                                                std::vector<ROI> &deltas,
                                                const ROI window)
{
    int N = int(rois.size());
    if(N <= 0) return std::vector<Result>();
    
    // Split the Result into CLASS_NUM-1 vectors based on their class_id.
    std::vector<std::vector<Result>> split_results;
    for(int i=0; i<CLASS_NUM-1; i++)
    {
        split_results.push_back(std::vector<Result>());
    }
    
    for(int bid=0; bid < N; bid++)
    {
        int class_id = class_ids[bid];
        float class_score = probs[bid];
        // The result with class_id == 0 will be filtered out
        if(class_score <= ((float*)DETECTION_MIN_CONFIDENCE)[class_id] || class_id <= 0 || class_id >= 6 )
            continue;
        // Refine the roi by delta
        ROI refine_roi = apply_box_delta(rois[bid], deltas[bid],
                                         BBOX_STD_DEV, IMAGE_SHAPE_W, IMAGE_SHAPE_H);
        refine_roi.val[0] = std::min(std::max(float(round(refine_roi.val[0])), float(window.val[0])), float(window.val[2]));
        refine_roi.val[1] = std::min(std::max(float(round(refine_roi.val[1])), float(window.val[1])), float(window.val[3]));
        refine_roi.val[2] = std::min(std::max(float(round(refine_roi.val[2])), float(window.val[0])), float(window.val[2]));
        refine_roi.val[3] = std::min(std::max(float(round(refine_roi.val[3])), float(window.val[1])), float(window.val[3]));
        
        Result res;
        res.score = class_score;
        res.class_id = class_id;
        res.roi = refine_roi;
        if(refine_roi.val[0] < refine_roi.val[2]-MIN_OBJECT_SIZE &&
           refine_roi.val[1] < refine_roi.val[3]-MIN_OBJECT_SIZE)
            split_results[class_id-1].push_back(res);
    }
    
    // NMS filtering
    std::vector<Result> all_results;
    std::vector<std::vector<Result>>::iterator split_ite = split_results.begin();
    for(;split_ite<split_results.end(); split_ite++)
    {
        if(split_ite->empty())
            continue;
        non_max_suppression(*split_ite, DETECTION_NMS_THRESHOLD, DETECTION_MAX_INSTANCES, all_results);
    }
    // Get the top_k results only
    //std::sort(all_results.begin(), all_results.end(), base_on_score_descend);
    //return std::vector<Result>(all_results.begin(), all_results.begin()+
    //                             std::min(int(all_results.size()), int(DETECTION_MAX_INSTANCES)));
    // Pad zeros to MAX_NUM.
    //   Result t;
    //   memset(&t, 0, sizeof(t));
    //   while(all_results.size() < DETECTION_MAX_INSTANCES)
    //     all_results.push_back(t);
    return all_results;
}
// ANCHOR
std::vector<ROI> MaskRcnn::generate_anchors(int scale, std::vector<float> &ratios,
                                            cv::Size shape, int feature_stride, int anchor_stride)
{
    std::vector<ROI> anchor_rois;
    for(int shift_y=0; shift_y<shape.height; shift_y+=anchor_stride)
    {
        for(int shift_x=0; shift_x<shape.width; shift_x+=anchor_stride)
        {
            for(float ratio : ratios)
            {
                float w = scale * sqrt(ratio), h = scale / sqrt(ratio);
                ROI cur_roi;
                cur_roi.val[0] = shift_y * feature_stride - 0.5 * h;
                cur_roi.val[1] = shift_x * feature_stride - 0.5 * w;
                cur_roi.val[2] = shift_y * feature_stride + 0.5 * h;
                cur_roi.val[3] = shift_x * feature_stride + 0.5 * w;
                anchor_rois.push_back(cur_roi);
            }
        }
    }
    return anchor_rois;
}
std::vector<ROI> MaskRcnn::generate_pyramid_anchors()
{
    return generate_pyramid_anchors(RPN_ANCHOR_SCALES, RPN_ANCHOR_RATIOS,
                                    BACKBONE_SHAPES, BACKBONE_STRIDES, RPN_ANCHOR_STRIDE);
}
std::vector<ROI> MaskRcnn::generate_pyramid_anchors(int* scales_ptr, float* ratios_ptr,
                                                    std::vector<cv::Size> &feature_shapes,
                                                    int* feature_strides_ptr,
                                                    int anchor_stride)
{
    // Config Conversion.
    std::vector<int> scales(scales_ptr, scales_ptr+5);
    std::vector<int> feature_strides(feature_strides_ptr, feature_strides_ptr+5);
    std::vector<float> ratios(ratios_ptr, ratios_ptr+3);
    
    std::vector<ROI> anchors;
    for(int index=0; index<scales.size(); index++)
    {
        std::vector<ROI> cur_anchors = generate_anchors(scales[index], ratios,
                                                        feature_shapes[index], feature_strides[index], anchor_stride);
        anchors.insert(anchors.end(), cur_anchors.begin(), cur_anchors.end());
    }
    return anchors;
}

// PROPOSAL LAYER
std::vector<ROI> MaskRcnn::proposal_layer(std::vector<MLMultiArray *> &ml_probs,
                                          std::vector<MLMultiArray *> &ml_bboxes)
{
    int loop_count = 0, bbox_id = 0;
    
    std::vector<float> probs;
    std::vector<ROI> unrefine_rois;
    std::vector<int> bbox_ids;
    float thresh = -100000.0;
    for(int i=0; i<ml_probs.size(); i++)
    {
        MLMultiArray *prob = ml_probs[i];
        MLMultiArray *bbox = ml_bboxes[i];
        
        NSArray *prob_shape = prob.shape;
        NSArray *bbox_shape = bbox.shape;
        assert(prob_shape.count == 3 && bbox_shape.count == 3);
        assert([prob_shape[0] intValue] == 6 && [bbox_shape[0] intValue] == 12);
        assert([prob_shape[2] intValue] == [bbox_shape[2] intValue]);
        assert([prob_shape[1] intValue] == [bbox_shape[1] intValue]);
        
        int H = [prob_shape[1] intValue], W = [prob_shape[2] intValue];
        
        double* ptr = (double*)(prob.dataPointer);
        double* btr = (double*)(bbox.dataPointer);
        int step = H*W;
        double *c1_bg = ptr,      *c2_bg = ptr + 2*step, *c3_bg = ptr + 4*step;
        double *c1_fg = ptr+step, *c2_fg = ptr + 3*step, *c3_fg = ptr + 5*step;
        double *c1_y1 = btr,        *c2_y1 = btr + 4*step,  *c3_y1 = btr + 8*step;
        double *c1_x1 = c1_y1+step, *c2_x1 = c2_y1+step,    *c3_x1 = c3_y1+step;
        double *c1_y2 = c1_x1+step, *c2_y2 = c2_x1+step,    *c3_y2 = c3_x1+step;
        double *c1_x2 = c1_y2+step, *c2_x2 = c2_y2+step,    *c3_x2 = c3_y2+step;
        for(int k=0; k<H; k++)
        {
            for(int j=0; j<W; j++)
            {
                std::vector<float> roi_c1, roi_c2, roi_c3;
                float score_c1 = c1_fg[0] - c1_bg[0];
                if(score_c1 > thresh){
                    probs.push_back(score_c1);
                    ROI temp;
                    temp.val[0] = c1_y1[0];
                    temp.val[1] = c1_x1[0];
                    temp.val[2] = c1_y2[0];
                    temp.val[3] = c1_x2[0];
                    unrefine_rois.push_back(temp);
                    bbox_ids.push_back(bbox_id);
                }
                bbox_id ++;
                float score_c2 = c2_fg[0] - c2_bg[0];
                if(score_c2 > thresh){
                    probs.push_back(score_c2);
                    ROI temp;
                    temp.val[0] = c2_y1[0];
                    temp.val[1] = c2_x1[0];
                    temp.val[2] = c2_y2[0];
                    temp.val[3] = c2_x2[0];
                    unrefine_rois.push_back(temp);
                    bbox_ids.push_back(bbox_id);
                }
                bbox_id ++;
                float score_c3 = c3_fg[0] - c3_bg[0];
                if(score_c3 > thresh){
                    probs.push_back(score_c3);
                    ROI temp;
                    temp.val[0] = c3_y1[0];
                    temp.val[1] = c3_x1[0];
                    temp.val[2] = c3_y2[0];
                    temp.val[3] = c3_x2[0];
                    unrefine_rois.push_back(temp);
                    bbox_ids.push_back(bbox_id);
                }
                bbox_id ++;
                if(i == 0 && loop_count == 2000){
                    float min_val = 1000000.0f;
                    for(float val : probs)
                    {
                        if(val < min_val)
                            min_val = val;
                    }
                    thresh = min_val;
                }
                
                c1_bg++; c2_bg++; c3_bg++;
                c1_fg++; c2_fg++; c3_fg++;
                c1_y1++; c2_y1++; c3_y1++;
                c1_x1++; c2_y1++; c3_x1++;
                c1_y2++; c2_x1++; c3_y2++;
                c1_x2++; c2_y2++; c3_x2++;
                loop_count ++;
            }
        }
    }
    assert(probs.size() == unrefine_rois.size());
    assert(probs.size() == bbox_ids.size());
    int N = int(probs.size());
    if(N <= 0) return std::vector<ROI>();
    
    // Calc the minimal score threshold for anchor and box.
    int pre_nms_limit = std::min(1000, int(M_ANCHORS.size()));
    std::vector<float> temp = probs;
    sort(temp.begin(), temp.end());
    float thresh_score = temp[temp.size()-pre_nms_limit];
    // Get max-score 6000 proposals.
    std::vector<Result> filter_results;
    for(int i=0; i<unrefine_rois.size(); i++)
    {
        if(probs[i] >= thresh_score)
        {
            ROI refine_roi = apply_box_delta(M_ANCHORS[bbox_ids[i]], unrefine_rois[i], RPN_BBOX_STD_DEV, 1.0, 1.0);
            refine_roi.val[0] = std::min(std::max(float(round(refine_roi.val[0])), 0.f), float(IMAGE_SHAPE_H)) / IMAGE_SHAPE_H;
            refine_roi.val[1] = std::min(std::max(float(round(refine_roi.val[1])), 0.f), float(IMAGE_SHAPE_W)) / IMAGE_SHAPE_W;
            refine_roi.val[2] = std::min(std::max(float(round(refine_roi.val[2])), 0.f), float(IMAGE_SHAPE_H)) / IMAGE_SHAPE_H;
            refine_roi.val[3] = std::min(std::max(float(round(refine_roi.val[3])), 0.f), float(IMAGE_SHAPE_W)) / IMAGE_SHAPE_W;
            Result res;
            res.roi = refine_roi;
            res.score = probs[i];
            if(refine_roi.val[0] < refine_roi.val[2]-MIN_OBJECT_SIZE/IMAGE_SHAPE_H && refine_roi.val[1] < refine_roi.val[3]-MIN_OBJECT_SIZE/IMAGE_SHAPE_W)
                filter_results.push_back(res);
        }
    }
    // NMS Procession.
    std::vector<Result> all;
    non_max_suppression(filter_results, RPN_NMS_THRESHOLD, POST_NMS_ROIS_INFERENCE, all);
    // Pad to NUM with zeros.
    std::vector<ROI> ret;
    int index = 0;
    float thresh_min_object_size = (MIN_OBJECT_SIZE*1.0f/IMAGE_SHAPE_W)*
                                    (MIN_OBJECT_SIZE*1.0f/IMAGE_SHAPE_W);
    while (index < all.size() && ret.size() < POST_NMS_ROIS_INFERENCE) {
        ROI cur = all[index].roi;
        if((cur.val[2]-cur.val[0])*(cur.val[3]-cur.val[1]) > thresh_min_object_size)
            ret.push_back(all[index].roi);
        index ++;
    }
    
    return ret;
}
// // ROI_Align layer
std::vector<cv::Mat> MaskRcnn::crop_and_resize(std::vector<cv::Mat> &fm, ROI box, cv::Size crop_size, bool is_normalized)
{
    int w = fm[0].cols, h = fm[0].rows;
    int y1, x1, y2, x2;
    if(is_normalized)
    {
        y1 = std::min(h, std::max(0, int(round(box.val[0]*h))));
        x1 = std::min(w, std::max(0, int(round(box.val[1]*w))));
        y2 = std::min(h, std::max(0, int(round(box.val[2]*h))));
        x2 = std::min(w, std::max(0, int(round(box.val[3]*w))));
    }
    else
    {
        y1 = std::min(h, std::max(0, int(round(box.val[0]/IMAGE_SHAPE_H*h))));
        x1 = std::min(w, std::max(0, int(round(box.val[1]/IMAGE_SHAPE_W*w))));
        y2 = std::min(h, std::max(0, int(round(box.val[2]/IMAGE_SHAPE_H*h))));
        x2 = std::min(w, std::max(0, int(round(box.val[3]/IMAGE_SHAPE_W*w))));
    }
    cv::Rect roi(x1, y1, x2-x1, y2-y1);
    std::vector<cv::Mat> crop_features;
    for(cv::Mat feature_map : fm)
    {
        cv::Mat crop_feature;
        cv::resize(feature_map(roi), crop_feature, crop_size,
                   0, 0, cv::INTER_LINEAR);
        crop_feature.convertTo(crop_feature, CV_64FC4);
        crop_features.push_back(crop_feature);
    }
    return crop_features;
}
std::vector<std::vector<cv::Mat>> MaskRcnn::roi_align(std::vector<std::vector<cv::Mat>> &feature_maps,
                                                      cv::Size pool_shape,
                                                      std::vector<ROI> &boxes,
                                                      bool is_normalized)
{
    std::vector<std::vector<cv::Mat>> features;
    float image_area = IMAGE_SHAPE_H * IMAGE_SHAPE_W;
    for(ROI box : boxes)
    {
        float h = box.val[2] - box.val[0], w = box.val[3] - box.val[1];
        if(!is_normalized){
            h /= IMAGE_SHAPE_H;
            w /= IMAGE_SHAPE_W;
        }
        float roi_level_f = log(sqrt(w*h) / (224.f/sqrt(image_area))) / log(2.f);
        int roi_level = std::min(5, std::max(2, 4 + int(round(roi_level_f))));
        
        std::vector<cv::Mat> pool_fm = crop_and_resize(feature_maps[roi_level-2], box,
                                                       pool_shape, is_normalized);
        features.push_back(pool_fm);
    }
    return features;
}
std::vector<cv::Mat> MaskRcnn::crop_and_resize(MLMultiArray *fm, ROI box, cv::Size crop_size, bool is_normalized)
{
    int w = [fm.shape[2] intValue];
    int h = [fm.shape[1] intValue];
    int chn = [fm.shape[0] intValue];
    int y1, x1, y2, x2;
    if(is_normalized)
    {
        y1 = std::min(h, std::max(0, int(round(box.val[0]*h))));
        x1 = std::min(w, std::max(0, int(round(box.val[1]*w))));
        y2 = std::min(h, std::max(0, int(round(box.val[2]*h))));
        x2 = std::min(w, std::max(0, int(round(box.val[3]*w))));
    }
    else
    {
        y1 = std::min(h, std::max(0, int(round(box.val[0]/IMAGE_SHAPE_H*h))));
        x1 = std::min(w, std::max(0, int(round(box.val[1]/IMAGE_SHAPE_W*w))));
        y2 = std::min(h, std::max(0, int(round(box.val[2]/IMAGE_SHAPE_H*h))));
        x2 = std::min(w, std::max(0, int(round(box.val[3]/IMAGE_SHAPE_W*w))));
    }
    double *qtr = (double*)fm.dataPointer;
    std::vector<cv::Mat> crop_features;
    cv::Mat temp( y2-y1, x2-x1, CV_32FC4);
    for(int c=0; c<chn; c++)
    {
        double *qtr_c = qtr + c*h*w + y1*w;
        int cur_c = c % 4;
        for(int y=y1; y<y2; y++)
        {
            float *ptr = temp.ptr<float>(y-y1);
            for(int x=x1; x<x2; x++)
            {
                ptr[(x-x1)*4 + cur_c] = qtr_c[x];
            }
            qtr_c += w;
        }
        if(cur_c == 3)
        {
            cv::Mat crop_feature;
            cv::resize(temp, crop_feature, crop_size,
                       0, 0, cv::INTER_LINEAR);
            crop_features.push_back(crop_feature);
        }
    }
    
    return crop_features;
}
std::vector<std::vector<cv::Mat>> MaskRcnn::roi_align(std::vector<MLMultiArray *> &feature_maps,
                                                      cv::Size pool_shape,
                                                      std::vector<ROI> &boxes,
                                                      bool is_normalized)
{
    std::vector<std::vector<cv::Mat>> features;
    float image_area = IMAGE_SHAPE_H * IMAGE_SHAPE_W;
    for(ROI box : boxes)
    {
        float h = box.val[2] - box.val[0], w = box.val[3] - box.val[1];
        if(!is_normalized){
            h /= IMAGE_SHAPE_H;
            w /= IMAGE_SHAPE_W;
        }
        float roi_level_f = log(sqrt(w*h) / (224.f/sqrt(image_area))) / log(2.f);
        int roi_level = std::min(5, std::max(2, 4 + int(round(roi_level_f))));
        
        std::vector<cv::Mat> pool_fm = crop_and_resize(feature_maps[roi_level-2], box,
                                                       pool_shape, is_normalized);
        features.push_back(pool_fm);
    }
    return features;
}
///////////////////////////////////////////////////
// Depth Detector
///////////////////////////////////////////////////
DepthDetector::DepthDetector()
{
    NSString * path = [[NSBundle mainBundle] pathForResource:@"unpool1_param" ofType:@"txt"];
    std::string file_path = [path UTF8String];
    m_bn_params_1 = parse_bn_param(file_path);
    path = [[NSBundle mainBundle] pathForResource:@"unpool2_param" ofType:@"txt"];
    file_path = [path UTF8String];
    m_bn_params_2 = parse_bn_param(file_path);
    path = [[NSBundle mainBundle] pathForResource:@"unpool3_param" ofType:@"txt"];
    file_path = [path UTF8String];
    m_bn_params_3 = parse_bn_param(file_path);
    path = [[NSBundle mainBundle] pathForResource:@"unpool4_param" ofType:@"txt"];
    file_path = [path UTF8String];
    m_bn_params_4 = parse_bn_param(file_path);
}
DepthDetector::~DepthDetector()
{}
cv::Mat DepthDetector::preprocess(cv::Mat image)
{
    cv::Mat dst_image;
    cv::resize(image, dst_image, m_input_size, 0, 0, cv::INTER_AREA);
    //cv::cvtColor(dst_image, dst_image, CV_BGR2RGB);
    dst_image.convertTo(dst_image, CV_32FC3);
    cv::Mat rgb[3];
    cv::split(dst_image, rgb);
    rgb[0] -= 123.0f;
    rgb[1] -= 116.0f;
    rgb[2] -= 103.0f;
    cv::Mat input_image(m_input_size.height, m_input_size.width, CV_32FC3);
    cv::merge(rgb, 3, input_image);
    input_image /= 255.0f;
    
    return input_image;
}
BN_PARAMS DepthDetector::parse_bn_param(std::string file_path)
{
    BN_PARAMS params;
    BN_PARAM ch_param;
    std::ifstream infile(file_path);
    double gamma, variance;
    while (infile >> ch_param.beta >> gamma >> ch_param.mean >> variance) {
        ch_param.scale = gamma/(sqrt(variance)+ 0.00001);
        params.push_back(ch_param);
    }
    return params;
}
double DepthDetector::bn_and_relu(double x, BN_PARAM param)
{
        return param.scale*(x - param.mean) + param.beta;;
}
MLMultiArray * DepthDetector::ibr(std::vector<MLMultiArray*> &tensors, BN_PARAMS params)
{
    int c = [tensors[0].shape[0] intValue];
    int h = [tensors[0].shape[1] intValue];
    int w = [tensors[0].shape[2] intValue];
    if(c == 0 || h == 0 || w ==0 ||
       c%64 != 0 || h%8 != 0 || w%10 != 0)
        return nil;
    assert(tensors.size() == 4);
    NSArray * new_shape = @[[NSNumber numberWithInt:c],
                            [NSNumber numberWithInt:2*h],
                            [NSNumber numberWithInt:2*w]];
    MLMultiArray *array = [[MLMultiArray alloc] initWithShape:new_shape dataType:MLMultiArrayDataTypeDouble error:nil];
    double *ptr_a = (double*)tensors[0].dataPointer;
    double *ptr_b = (double*)tensors[1].dataPointer;
    double *ptr_c = (double*)tensors[2].dataPointer;
    double *ptr_d = (double*)tensors[3].dataPointer;
    double *ptr   = (double*)array.dataPointer;
    for(int ci=0; ci<c; ci++)
    {
        BN_PARAM param = params[ci];
        double thresh = -param.beta/param.scale + param.mean;
        for(int i=0; i<2*h; i++)
        {
            if(i % 2 == 0)
            {
                for(int j=0; j<w; j++)
                {
                    *ptr++ = *ptr_a > thresh ? bn_and_relu(*ptr_a, param) : 0;
                    ptr_a ++;
                    *ptr++ = *ptr_c > thresh ? bn_and_relu(*ptr_c, param) : 0;
                    ptr_c ++;
                }
            }
            else
            {
                for(int j=0; j<w; j++)
                {
                    *ptr++ = *ptr_b > thresh ? bn_and_relu(*ptr_b, param) : 0;
                    ptr_b ++;
                    *ptr++ = *ptr_d > thresh ? bn_and_relu(*ptr_d, param) : 0;
                    ptr_d ++;
                }
            }
        }
    }
    return array;
}
int compare_value(double i, double j, double k, double l){
    if(i>j){
        if(i>k)
            return i>l? 0:3;
        else
            return k>l? 2:3;
    }
    else
    {
        if(j>k)
            return j>l? 1:3;
        else
            return k>l? 2:3;
    }
}
std::vector<cv::Mat> DepthDetector::detect(cv::Mat image)
{
    double t_start = cv::getTickCount();
    cv::Mat input_image = preprocess(image);
    if(input_image.empty())
        return std::vector<cv::Mat>();
    
    MLMultiArray *input_array = MatToMLMultiArray(input_image);
    
    // Get scene segmentation mat.
    scene_segment *seg_net = [DPModelNet scene_segment];
    scene_segmentOutput *seg_output = [seg_net predictionFromPlaceholder__0:input_array error:nil];
    // Convert to Depth Mat.
    MLMultiArray * scene_mask = seg_output.seg_net__output_124__add__0;
    if([scene_mask.shape[0] intValue] != 4  ||
       [scene_mask.shape[1] intValue] != 128||
       [scene_mask.shape[2] intValue] != 160 )
        return std::vector<cv::Mat>();
    int h = [scene_mask.shape[1] intValue];
    int w = [scene_mask.shape[2] intValue];
    if(h != m_input_size.height/2 || w != m_input_size.width/2)
        return std::vector<cv::Mat>();
    
    cv::Mat scene_mat(h, w, CV_8UC3);
    
    std::vector<cv::Scalar> colors;
    colors.push_back(cv::Scalar(0,0,0)); // background
    colors.push_back(cv::Scalar(255,255,255)); // wall
    colors.push_back(cv::Scalar(0,255,0)); // grass
    colors.push_back(cv::Scalar(0,0,255)); // water
    double *ptr_0 = (double*)scene_mask.dataPointer;
    double *ptr_1 = ptr_0 + h*w;
    double *ptr_2 = ptr_1 + h*w;
    double *ptr_3 = ptr_2 + h*w;
    for (int j=0; j<h; j++) {
        uchar* dst = scene_mat.ptr<uchar>(j);
        for (int i=0; i<w; i++) {
            int scene_id = compare_value(*ptr_0++, *ptr_1++, *ptr_2++, *ptr_3++);
            dst[i*3+0] = colors[scene_id].val[0];
            dst[i*3+1] = colors[scene_id].val[1];
            dst[i*3+2] = colors[scene_id].val[2];
        }
    }
    cv::Mat scene_full;
    if(scene_mat.empty() || image.cols <= 10 || image.rows <= 10 ||
       h <= 10 || w <= 10)
        return std::vector<cv::Mat>();
    
    cv::resize(scene_mat, scene_full, cv::Size(image.cols, image.rows));
    
    // DEPTH Detection.
    // Unpool4 - Interleave and batchnormal and relu.
    MLMultiArray * unpool4_input = seg_output.MobilenetV1__Conv2d_13_pointwise__relu__0;
    if([unpool4_input.shape[0] intValue] != 1024  ||
       [unpool4_input.shape[1] intValue] != 8||
       [unpool4_input.shape[2] intValue] != 10 )
        return std::vector<cv::Mat>();
    depth_unpool4 *unpool4 = [DPModelNet depth_unpool4];
    depth_unpool4Output *output_4 = [unpool4 predictionFromUnpool_conv4__Placeholder__0:unpool4_input error:nil];

    std::vector<MLMultiArray*> unpool4_abcd;
    unpool4_abcd.push_back( output_4.depth_net__unpool_conv4__a__Conv2D__0 );
    unpool4_abcd.push_back( output_4.depth_net__unpool_conv4__b__Conv2D__0 );
    unpool4_abcd.push_back( output_4.depth_net__unpool_conv4__c__Conv2D__0 );
    unpool4_abcd.push_back( output_4.depth_net__unpool_conv4__d__Conv2D__0 );
    MLMultiArray * unpool3_input = ibr(unpool4_abcd, m_bn_params_4);
    if(unpool3_input == nil)
        return std::vector<cv::Mat>();
    // Unpool3
    depth_unpool3 *unpool3 = [DPModelNet depth_unpool3];
    depth_unpool3Output *output_3 = [unpool3 predictionFromUnpool_conv3__Placeholder__0:unpool3_input error:nil];

    std::vector<MLMultiArray*> unpool3_abcd;
    unpool3_abcd.push_back( output_3.depth_net__unpool_conv3__a__Conv2D__0 );
    unpool3_abcd.push_back( output_3.depth_net__unpool_conv3__b__Conv2D__0 );
    unpool3_abcd.push_back( output_3.depth_net__unpool_conv3__c__Conv2D__0 );
    unpool3_abcd.push_back( output_3.depth_net__unpool_conv3__d__Conv2D__0 );
    MLMultiArray * unpool2_input = ibr(unpool3_abcd, m_bn_params_3);
    if(unpool2_input == nil)
        return std::vector<cv::Mat>();
    // Unpool2
    depth_unpool2 *unpool2 = [DPModelNet depth_unpool2];
    depth_unpool2Output *output_2 = [unpool2 predictionFromUnpool_conv2__Placeholder__0:unpool2_input error:nil];
//    t = cv::getTickCount()-t;
//    std::cout << "unpool2 : " << t/(cv::getTickFrequency())*1000 << "ms" << std::endl;
//
//    t = cv::getTickCount();
    std::vector<MLMultiArray*> unpool2_abcd;
    unpool2_abcd.push_back( output_2.depth_net__unpool_conv2__a__Conv2D__0 );
    unpool2_abcd.push_back( output_2.depth_net__unpool_conv2__b__Conv2D__0 );
    unpool2_abcd.push_back( output_2.depth_net__unpool_conv2__c__Conv2D__0 );
    unpool2_abcd.push_back( output_2.depth_net__unpool_conv2__d__Conv2D__0 );
    MLMultiArray * unpool1_input = ibr(unpool2_abcd, m_bn_params_2);
    if(unpool1_input == nil)
        return std::vector<cv::Mat>();
//    t = cv::getTickCount()-t;
//    std::cout << "2 ibr : " << t/(cv::getTickFrequency())*1000 << "ms" << std::endl;
//
//    t = cv::getTickCount();
    // Unpool1
    depth_unpool1 *unpool1 = [DPModelNet depth_unpool1];
    depth_unpool1Output *output_1 = [unpool1 predictionFromUnpool_conv1__Placeholder__0:unpool1_input error:nil];
//    t = cv::getTickCount()-t;
//    std::cout << "unpool1 : " << t/(cv::getTickFrequency())*1000 << "ms" << std::endl;
//
//    t = cv::getTickCount();
    std::vector<MLMultiArray*> unpool1_abcd;
    unpool1_abcd.push_back( output_1.depth_net__unpool_conv1__a__Conv2D__0 );
    unpool1_abcd.push_back( output_1.depth_net__unpool_conv1__b__Conv2D__0 );
    unpool1_abcd.push_back( output_1.depth_net__unpool_conv1__c__Conv2D__0 );
    unpool1_abcd.push_back( output_1.depth_net__unpool_conv1__d__Conv2D__0 );
    MLMultiArray * unpool1_output = ibr(unpool1_abcd, m_bn_params_1);
    if(unpool1_output == nil)
        return std::vector<cv::Mat>();
//    t = cv::getTickCount()-t;
//    std::cout << "1 ibr : " << t/(cv::getTickFrequency())*1000 << "ms" << std::endl;
//
//    t = cv::getTickCount();
    // Final conv.
    depth_final_conv *final_conv_net = [DPModelNet depth_final_conv];
    depth_final_convOutput *final_output = [final_conv_net predictionFromFinal_conv__Placeholder__0:unpool1_output error:nil];
    MLMultiArray *final_mask = final_output.depth_net__conv_pred__Conv2D__0;

//    t = cv::getTickCount()-t;
//    std::cout << "final conv : " << t/(cv::getTickFrequency())*1000 << "ms" << std::endl;
    // Convert to Depth Mat.
    h = [final_mask.shape[1] intValue];
    w = [final_mask.shape[2] intValue];
    if(h != m_input_size.height/2 || w != m_input_size.width/2 ||
       image.cols <= 10 || image.rows <= 10 ||
       h <= 10 || w <= 10)
        return std::vector<cv::Mat>();
    
    cv::Mat depth_mat(h, w, CV_32FC1);
    double *src = (double*)final_mask.dataPointer;
    for (int j=0; j<h; j++) {
        float* dst = depth_mat.ptr<float>(j);
        for (int i=0; i<w; i++) {
            *dst++ = float(*src++);
        }
    }
    cv::Mat depth_full;
    cv::resize(depth_mat, depth_full, cv::Size(image.cols, image.rows));
    cv::normalize(depth_full, depth_full, 255, 0, CV_MINMAX);

    cv::Mat depth_u, depth_color;
    depth_full.convertTo(depth_u, CV_8UC1);
    cv::cvtColor(depth_u, depth_color, CV_GRAY2BGR);
    
//    double t = cv::getTickCount()-t_start;
//    std::cout << "Depth and Segment time : " << t/(cv::getTickFrequency())*1000 << "ms" << std::endl;
    std::vector<cv::Mat> results;
    results.push_back(depth_color);
    results.push_back(scene_full);
    return results;
}
///////////////////////////////////////////////////
// Output for chunyuan
///////////////////////////////////////////////////
@interface Detect_obj ()
{
    MaskRcnn mask_detector;
    DepthDetector depth_detector;
}

@end

@implementation Detect_obj

+ (Detect_obj *)detectOBJ {
    static Detect_obj *detect = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        detect = [[Detect_obj alloc] init];
    });
    return detect;
}

- (void)reset:(float *)detectionMinConfidence {
    mask_detector.reset(detectionMinConfidence);
}
- ( std::vector<OneMaskObject>)testDetect:(cv::Mat)image {
    //MaskRcnn detector;
    std::vector<OneMaskObject> detections = mask_detector.detect(image);
 
    return detections;
}
- (std::vector<cv::Mat>)testDepthDetect:(cv::Mat)image  {
    //DepthDetector detector;
    std::vector<cv::Mat> depth_and_scene_images = depth_detector.detect(image);
    return depth_and_scene_images;
}
@end
