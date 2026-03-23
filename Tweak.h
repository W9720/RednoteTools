/**
 * RednoteTools v1.0
 * 小红书去水印下载工具
 * 
 * Author: 喜爱民谣
 */

#ifndef Tweak_h
#define Tweak_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

#pragma mark - 笔记相关

@interface XYPHMediaSaveConfig : NSObject
@property (nonatomic) bool disableSave;
@property (nonatomic) bool disableWatermark;
@property (nonatomic) bool disableWeiboCover;
@end

@interface XYVFVideoDownloaderManager : NSObject
@property (nonatomic) bool disableWatermark;
@end

@interface _TtC12XYNoteModule16ImageSaveService : NSObject
@end

@interface XYVFExpManager : NSObject
+ (bool)livePhotoWatermarkSwitch;
@end

@interface XYPHNoteImageInfo : NSObject
@property (nonatomic, copy) NSString *fileId;
@property (nonatomic, copy) NSString *livePhotoVideoFileId;
@property (nonatomic, retain) id livePhotoVideoInfo;
@end

@interface _TtC11XYNoteBasic7IBAsset : NSObject
@property (nonatomic, copy) NSString *livePhotoVideoFileId;
@property (nonatomic, copy) NSURL *livePhotoVideoURL;
@end

@interface XYPHFeedNotePhotoSaveActionHandler : NSObject
@end

@interface _TtC9XYPostKit35PostFlowLivePhotoWatermarkOperation : NSObject
@end

@interface XYPKPostModel : NSObject
@property (nonatomic) bool disableWatermarkWhenSavingAlbum;
@end


#pragma mark - 评论区相关

@interface XYCommentImageItem : NSObject
@property (nonatomic, copy) NSString *livePhotoMediaInfo;
@property (nonatomic, copy) NSString *livePhotoVideoId;
@end

@interface XYImageCommentManager : NSObject
- (void)downloadWithWatermark:(id)url completion:(void (^)(UIImage *))completion;
- (void)showResultWithIsSuccess:(bool)isSuccess;
@end

@interface _TtC12XYNoteModule23CommentMediaSaveService : NSObject
- (void)showResultWithIsSuccess:(bool)isSuccess;
@end

#pragma mark - Live Photo 管理器

@interface XYPKLivePhotoManager : NSObject
+ (long long)convertImageToLivePhotoFormatNewWithInputImagePath:(id)inputImagePath outputImageURL:(id)outputImageURL assetID:(id)assetID;
+ (void)preConvertVideoToLivePhotoFormatWithInputVideoPath:(id)inputVideoPath outputVideoURL:(id)outputVideoURL assetID:(id)assetID completion:(void (^)(BOOL success))completion;
@end

#pragma mark - 表情包

@interface _TtCC12XYNoteModule25MemePreviewPageController12MiddleCanvas : UIView
- (void)xhs_addSaveButton;
- (void)xhs_saveMeme;
- (void)xhs_showToast:(NSString *)message;
- (void)xhs_image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
@end

@interface _TtCC12XYNoteModule25MemePreviewPageController13AddMemeButton : UIButton
@property (nonatomic, readonly) double width;
@property (nonatomic, readonly) double height;
@property (nonatomic) bool isAdded;
- (void)xhs_addSaveButton;
- (void)xhs_saveMeme;
- (UIImageView *)xhs_findImageViewInView:(UIView *)view;
- (void)xhs_image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
- (void)xhs_showToast:(NSString *)message;
@end

#pragma mark - UIColor 扩展

@interface UIColor (XYHomeModule)
+ (id)xy_colorWithHex:(unsigned int)hex;
+ (id)xy_colorWithHex:(unsigned int)hex alpha:(double)alpha;
@end

#pragma mark - 图片浏览器

@interface _TtC11XYNoteBasic14IBNumIndicator : UIView
@property (nonatomic, retain) UILabel *indexer;
- (void)xhs_addDownloadButtons;
- (void)xhs_saveCurrentImage;
- (void)xhs_saveAllImages;
- (void)xhs_saveImageAtIndex:(long long)index showToast:(BOOL)showToast;
- (void)xhs_saveImageAtIndex:(long long)index noteId:(NSString *)noteId completion:(void (^)(BOOL success))completion;
- (void)xhs_saveImageAtIndexInternal:(long long)index fromCollection:(UICollectionView *)collection completion:(void (^)(BOOL success))completion;
- (void)xhs_saveLivePhotoWithImageURL:(NSURL *)imageURL videoURL:(NSURL *)videoURL completion:(void (^)(BOOL success))completion;
- (UILabel *)xhs_createProgressToast;
- (UIImageView *)xhs_findImageViewInView:(UIView *)view;
- (id)xhs_findImageBrowser;
- (void)xhs_showToast:(NSString *)message;
@end

@interface _TtC11XYNoteBasic12ImageBrowser : UIView
@property (nonatomic) long long displayIndex;
@property (nonatomic) double indicatorDissmissDelay;
@end

@interface _TtC11XYNoteBasic11IBViewModel : NSObject
@property (nonatomic, readonly) long long amount;
@property (nonatomic) long long anchor;
@end

#endif /* Tweak_h */
