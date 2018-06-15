# MaskRCNN_iOS

> An implementation of MaskRCNN  __based on CoreML__.

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

## Workflow

Take the MaskRCNN as an example, some layers are not supported by CoreML. We implement those parts in c++ and then convert variables between<font color=#0099ff> __c++ structures__(blue parts)</font> and<font color=#999900> __MLMultiArray__(yellow parts)</font>.

So you can see this:

<div align=center>
<img width=350 src="https://wx3.sinaimg.cn/mw1024/89ef5361ly1fsbvb2eo43j20hj0inabi.jpg"/>
</div>
    
## Contact

If you have any questions about this project. then send an email to buptmsg@gmail.com to let me know.    
