# MaskRCNN_iOS

> An implementation of MaskRCNN  __based on CoreML__.

[![996.icu](https://img.shields.io/badge/link-996.icu-red.svg)](https://996.icu)  [![LICENSE](https://img.shields.io/badge/license-NPL%20(The%20996%20Prohibited%20License)-blue.svg)](https://github.com/996icu/996.ICU/blob/master/LICENSE)

## Introduction

This project implements a __MaskRCNN model__ for person/cat/dog/table/face detection and segmentation which is trained by ourselves.
    
Also it includes another model for __semantic segmentation and depth estimation__.
    
The content is like this:

<div align=center>
<img width=700 src="https://wx4.sinaimg.cn/mw1024/89ef5361ly1fsbvb2jat6j20yo0icac6.jpg"/>
</div>


## Performance

<div align=center>
<img width=700 src="https://wx4.sinaimg.cn/mw1024/89ef5361ly1fsbvb2amarj20xt0fkdh2.jpg"/>
</div>

## Models

To use this project, you need to download the [pre-trained models](https://pan.baidu.com/s/1OHHLX24Z4fYEM6J2YNaC5A) and drag these models into this project in xcode. Or you can put them in ./DPFruit directly.

Also do not forget the opencv2.framework.

## Workflow

Take the MaskRCNN as an example, some layers are not supported by CoreML. We implement those parts in c++ and then convert variables between<font color=#0099ff> __c++ structures__(blue parts)</font> and<font color=#999900> __MLMultiArray__(yellow parts)</font>.

So you can see this:

<div align=center>
<img width=350 src="https://wx3.sinaimg.cn/mw1024/89ef5361ly1fsbvb2eo43j20hj0inabi.jpg"/>
</div>
    
## Contact

If you have any questions about this project. then send an email to buptmsg@gmail.com to let me know.    
