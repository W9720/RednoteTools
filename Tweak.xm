/**

* 小红书去水印下载工具
*
* 作者: 喜爱民谣
* /

#import "Tweak.h"
#import 
#import "PopupView.h" // 新增：引入弹窗头文件
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// 启动时打印用户头像相关信息
__attribute__((constructor)) void findUserAvatar() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // 1. 打印NSUserDefaults里的用户信息（小红书常用key）
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *allData = [defaults dictionaryRepresentation];
        NSLog(@"📱 小红书NSUserDefaults数据：%@", allData);
        
        // 2. Hook 小红书用户信息单例（通用写法）
        Class userInfoClass = NSClassFromString(@"XUserInfo"); // 小红书用户信息类名（示例，需验证）
        if (userInfoClass) {
            id userInstance = [userInfoClass performSelector:NSSelectorFromString(@"sharedInstance")];
            if (userInstance) {
                // 打印所有属性，找头像相关字段（如avatar、headImage、profileImage）
                unsigned int count;
                objc_property_t *props = class_copyPropertyList([userInstance class], &count);
                for (int i=0; i<count; i++) {
                    const char *propName = property_getName(props[i]);
                    NSString *propStr = [NSString stringWithUTF8String:propName];
                    id propValue = [userInstance valueForKey:propStr];
                    NSLog(@"🔑 用户信息属性 %@: %@", propStr, propValue);
                }
                free(props);
            }
        }
    });
}


// 随便找个你已经在跑的初始化函数里加
#import "PopupView.h"

__attribute__((constructor)) void initMe() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSLog(@"🔥 强制显示弹窗");
        [PopupView showPopupIfNeeded];
    });
}

外部 "C"  void showCopyrightAnimation(void);

静态NSMutableDictionary *livePhotoUrlCache = nil;
静态NSMutableDictionary *评论动态照片缓存 = 无;


%hook XYPHAppDelegate // 小红书的AppDelegate类（项目已适配）

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig; // 执行原方法
    
    // 延迟0.5秒显示弹窗（确保APP加载完成）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [PopupView showPopupIfNeeded]; // 显示弹窗
        showCopyrightAnimation(); // 原有版权动画，保留
    });
    
    返回结果;
}

%end

#pragma mark - 笔记去水印

%hook XYPHMediaSaveConfig
- (bool)禁用保存 { return NO; }
- (bool)disableWatermark { return YES; }
- (bool)disableWeiboCover { return YES; }
- (void)setDisableSave:(bool)value { %orig(NO); }
- (void)setDisableWatermark:(bool)value { %orig(YES); }
- (void)setDisableWeiboCover:(bool)value { %orig(YES); }
%end

%hook XYVF视频下载器管理器
- (bool)disableWatermark { return YES; }
- (void)setDisableWatermark:(bool)value { %orig(YES); }
%end

%hook _TtC12XYNoteModule16ImageSaveService
- (void)saveImageAt:(long long)index from:(id)source disableWatermark:(bool)disableWatermark completion:(id)completion {
    %orig(index, source, YES, completion);
}
- (void)saveImageWithoutManualTrackAt:(long long)index from:(id)source disableWatermark:(bool)disableWatermark completion:(id)completion {
    %orig(index, source, YES, completion);
}
%end

%hook XYVFExpManager
+ (bool)livePhotoWatermarkSwitch { return NO; }
%end

#pragma mark - Live Photo 去水印

%hook XYPHNoteImageInfo
- (id)livePhotoVideoInfo {
    id videoInfo = %orig;
    if (videoInfo) {
        @try {
            NSString *fileId = [self valueForKey:@"livePhotoVideoFileId"];
            if (!fileId) fileId = [self valueForKey:@"fileId"];
            id stream = [[videoInfo valueForKey:@"media"] valueForKey:@"stream"];
            if (stream) {
                NSArray *h265 = [stream valueForKey:@"h265"];
                NSArray *h264 = [stream valueForKey:@"h264"];
                NSString *url = (h265.count > 0) ? [h265[0] valueForKey:@"url"] : 
                                (h264.count > 0) ? [h264[0] valueForKey:@"url"] : nil;
                if (fileId && url) livePhotoUrlCache[fileId] = url;
            }
        } @catch (NSException *e) {}
    }
    return videoInfo;
}
%end

%hook _TtC11XYNoteBasic7IBAsset
- (void)setLivePhotoVideoURL:(NSURL *)url {
    NSString *fileId = [self valueForKey:@"livePhotoVideoFileId"];
    NSString *cachedUrl = fileId ? livePhotoUrlCache[fileId] : nil;
    if (cachedUrl) {
        NSURL *newUrl = [NSURL URLWithString:cachedUrl];
        if (newUrl) { %orig(newUrl); return; }
    }
    %orig(url);
}
- (NSURL *)livePhotoVideoURL {
    NSURL *url = %orig;
    NSString *fileId = [self valueForKey:@"livePhotoVideoFileId"];
    NSString *cachedUrl = fileId ? livePhotoUrlCache[fileId] : nil;
    if (cachedUrl) {
        NSURL *newUrl = [NSURL URLWithString:cachedUrl];
        if (newUrl) return newUrl;
    }
    return url;
}
%end

%hook XYPHFeedNotePhotoSaveActionHandler
- (id)livePhotoWatermarkURL:(id)url livePhotoId:(id)photoId { return nil; }
- (void)requestWatermark:(id)watermark completion:(id)completion {
    if (completion) { void (^block)(id) = completion; block(nil); }
}
%end

%hook _TtC9XYPostKit35PostFlowLivePhotoWatermarkOperation
- (id)initWithSaveAsLivePhoto:(bool)saveAsLivePhoto livePhotoVideoPath:(id)videoPath sessionId:(id)sessionId disableWatermarkWhenSavingAlbum:(bool)disableWatermark completion:(id)completion {
    return %orig(saveAsLivePhoto, videoPath, sessionId, YES, completion);
}
%end

%hook XYPKPostModel
- (bool)disableWatermarkWhenSavingAlbum { return YES; }
- (void)setDisableWatermarkWhenSavingAlbum:(bool)value { %orig(YES); }
%end


#pragma mark - 评论区图片去水印

%hook XYImageCommentManager
- (void)saveImageWithUrl:(id)url authorId:(id)authorId {
    [self downloadWithWatermark:url completion:^(UIImage *image) {
        if (image) {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            [self showResultWithIsSuccess:YES];
        } else {
            [self showResultWithIsSuccess:NO];
        }
    }];
}
- (id)createFullWatermarkWith:(id)image userId:(id)userId scale:(double)scale { return nil; }
- (void)saveWithImage:(id)image to:(id)to and:(id)andParam filter:(id)filter data:(id)data cacheKey:(id)cacheKey isHdr:(bool)isHdr {
    if (image) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        [self showResultWithIsSuccess:YES];
    }
}
%end

#pragma mark - 评论区 Live Photo 缓存

%hook XYPHNoteComment
- (void)setCommentImages:(NSArray *)commentImages {
    %orig;
    if (commentImages.count > 0) {
        for (id item in commentImages) {
            @try {
                NSString *videoId = [item valueForKey:@"livePhotoVideoId"];
                NSString *mediaInfo = [item valueForKey:@"livePhotoMediaInfo"];
                if (videoId && mediaInfo && !commentLivePhotoCache[videoId]) {
                    NSData *jsonData = [mediaInfo dataUsingEncoding:NSUTF8StringEncoding];
                    NSDictionary *mediaDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
                    if (mediaDict) {
                        NSDictionary *stream = mediaDict[@"stream"];
                        NSString *url = nil;
                        if (stream[@"h265"] && [stream[@"h265"] count] > 0) {
                            url = stream[@"h265"][0][@"master_url"];
                            if (!url) url = stream[@"h265"][0][@"url"];
                        }
                        if (!url && stream[@"h264"] && [stream[@"h264"] count] > 0) {
                            url = stream[@"h264"][0][@"master_url"];
                            if (!url) url = stream[@"h264"][0][@"url"];
                        }
                        if (url) commentLivePhotoCache[videoId] = url;
                    }
                }
            } @catch (NSException *e) {}
        }
    }
}
%end

%hook XYCommentImageItem
- (NSString *)livePhotoMediaInfo {
    NSString *mediaInfo = %orig;
    if (mediaInfo) {
        @try {
            NSString *videoId = [self valueForKey:@"livePhotoVideoId"];
            if (videoId && !commentLivePhotoCache[videoId]) {
                NSData *jsonData = [mediaInfo dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *mediaDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
                if (mediaDict) {
                    NSDictionary *stream = mediaDict[@"stream"];
                    NSString *url = nil;
                    if (stream[@"h265"] && [stream[@"h265"] count] > 0) {
                        url = stream[@"h265"][0][@"master_url"];
                        if (!url) url = stream[@"h265"][0][@"url"];
                    }
                    if (!url && stream[@"h264"] && [stream[@"h264"] count] > 0) {
                        url = stream[@"h264"][0][@"master_url"];
                        if (!url) url = stream[@"h264"][0][@"url"];
                    }
                    if (url) commentLivePhotoCache[videoId] = url;
                }
            }
        } @catch (NSException *e) {}
    }
    return mediaInfo;
}
%end


#pragma mark - 评论区 Live Photo 保存

static void downloadFileToPath(NSString *urlString, NSString *destPath, void (^completion)(BOOL success)) {
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error || !location) { if (completion) completion(NO); return; }
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm removeItemAtPath:destPath error:nil];
        BOOL success = [fm moveItemAtURL:location toURL:[NSURL fileURLWithPath:destPath] error:nil];
        if (completion) completion(success);
    }];
    [task resume];
}

static void saveCommentLivePhoto(NSString *imageUrlString, NSString *videoUrlString, id service) {
    NSString *tempDir = NSTemporaryDirectory();
    NSString *imagePath = [tempDir stringByAppendingPathComponent:@"xhs_lp_img.jpg"];
    NSString *videoPath = [tempDir stringByAppendingPathComponent:@"xhs_lp_vid.mov"];
    NSString *outImagePath = [tempDir stringByAppendingPathComponent:@"xhs_lp_out_img.jpg"];
    NSString *outVideoPath = [tempDir stringByAppendingPathComponent:@"xhs_lp_out_vid.mov"];
    NSString *assetID = [[NSUUID UUID] UUIDString];
    
    NSString *jpgImageUrl = [imageUrlString containsString:@"format/heif"] 
        ? [imageUrlString stringByReplacingOccurrencesOfString:@"format/heif" withString:@"format/jpg"] 
        : imageUrlString;
    
    downloadFileToPath(jpgImageUrl, imagePath, ^(BOOL imgOK) {
        if (!imgOK) { dispatch_async(dispatch_get_main_queue(), ^{ [service showResultWithIsSuccess:NO]; }); return; }
        
        downloadFileToPath(videoUrlString, videoPath, ^(BOOL vidOK) {
            if (!vidOK) { dispatch_async(dispatch_get_main_queue(), ^{ [service showResultWithIsSuccess:NO]; }); return; }
            
            Class mgr = NSClassFromString(@"XYPKLivePhotoManager");
            if (!mgr) { dispatch_async(dispatch_get_main_queue(), ^{ [service showResultWithIsSuccess:NO]; }); return; }
            
            NSURL *outImgURL = [NSURL fileURLWithPath:outImagePath];
            NSURL *outVidURL = [NSURL fileURLWithPath:outVideoPath];
            
            if ([mgr convertImageToLivePhotoFormatNewWithInputImagePath:imagePath outputImageURL:outImgURL assetID:assetID] != 0) {
                dispatch_async(dispatch_get_main_queue(), ^{ [service showResultWithIsSuccess:NO]; });
                return;
            }
            
            [mgr preConvertVideoToLivePhotoFormatWithInputVideoPath:videoPath outputVideoURL:outVidURL assetID:assetID completion:^(BOOL cvtOK) {
                if (!cvtOK) { dispatch_async(dispatch_get_main_queue(), ^{ [service showResultWithIsSuccess:NO]; }); return; }
                
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    PHAssetCreationRequest *req = [PHAssetCreationRequest creationRequestForAsset];
                    PHAssetResourceCreationOptions *opts = [[PHAssetResourceCreationOptions alloc] init];
                    opts.shouldMoveFile = NO;
                    [req addResourceWithType:PHAssetResourceTypePhoto fileURL:outImgURL options:opts];
                    [req addResourceWithType:PHAssetResourceTypePairedVideo fileURL:outVidURL options:opts];
                } completionHandler:^(BOOL success, NSError *error) {
                    NSFileManager *fm = [NSFileManager defaultManager];
                    [fm removeItemAtPath:imagePath error:nil];
                    [fm removeItemAtPath:videoPath error:nil];
                    [fm removeItemAtPath:outImagePath error:nil];
                    [fm removeItemAtPath:outVideoPath error:nil];
                    dispatch_async(dispatch_get_main_queue(), ^{ [service showResultWithIsSuccess:success]; });
                }];
            }];
        });
    });
}

%hook _TtC12XYNoteModule23CommentMediaSaveService
- (void)saveLivePhotoWithNoteId:(id)noteId commentId:(id)commentId userId:(id)userId imageUrlString:(id)imageUrlString inputVideoId:(id)inputVideoId {
    NSString *cachedUrl = inputVideoId ? commentLivePhotoCache[inputVideoId] : nil;
    if (cachedUrl && imageUrlString) {
        saveCommentLivePhoto(imageUrlString, cachedUrl, self);
        return;
    }
    %orig;
}
%end


#pragma mark - 表情包保存

%hook _TtCC12XYNoteModule25MemePreviewPageController13AddMemeButton

- (void)didMoveToSuperview {
    %orig;
    if ([self superview]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self xhs_addSaveButton];
        });
    }
}

%new
- (void)xhs_addSaveButton {
    UIView *superview = [self superview];
    if (!superview || [superview viewWithTag:88888]) return;
    
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    saveBtn.tag = 88888;
    saveBtn.backgroundColor = [UIColor xy_colorWithHex:0xF2324B];
    saveBtn.layer.cornerRadius = self.layer.cornerRadius;
    saveBtn.clipsToBounds = YES;
    saveBtn.titleLabel.font = self.titleLabel.font;
    [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [saveBtn setTitle:@"保存表情" forState:UIControlStateNormal];
    
    CGRect addBtnFrame = self.frame;
    CGFloat spacing = 12;
    saveBtn.frame = CGRectMake(addBtnFrame.origin.x, 
                                addBtnFrame.origin.y - addBtnFrame.size.height - spacing, 
                                addBtnFrame.size.width, 
                                addBtnFrame.size.height);
    
    [saveBtn addTarget:self action:@selector(xhs_saveMeme) forControlEvents:UIControlEventTouchUpInside];
    [superview addSubview:saveBtn];
}

%new
- (void)xhs_saveMeme {
    UIView *superview = self.superview;
    UIImageView *memeImageView = nil;
    
    for (UIView *view in superview.subviews) {
        if ([NSStringFromClass([view class]) containsString:@"MemeImageView"]) {
            memeImageView = (UIImageView *)view;
            break;
        }
    }
    
    if (!memeImageView) memeImageView = [self xhs_findImageViewInView:superview];
    
    if (memeImageView && memeImageView.image) {
        UIImageWriteToSavedPhotosAlbum(memeImageView.image, self, @selector(xhs_image:didFinishSavingWithError:contextInfo:), nil);
        return;
    }
    
    UIResponder *responder = self;
    while (responder) {
        NSString *className = NSStringFromClass([responder class]);
        if ([className containsString:@"MemePreviewPageController"]) {
            @try {
                UIImage *cachedImage = [responder valueForKey:@"cachedImage"];
                if (cachedImage) {
                    UIImageWriteToSavedPhotosAlbum(cachedImage, self, @selector(xhs_image:didFinishSavingWithError:contextInfo:), nil);
                    return;
                }
                
                NSURL *memeUrl = [responder valueForKey:@"memeUrl"];
                if (memeUrl) {
                    [self xhs_showToast:@"正在保存..."];
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                        NSData *data = [NSData dataWithContentsOfURL:memeUrl];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (data) {
                                UIImage *image = [UIImage imageWithData:data];
                                if (image) {
                                    UIImageWriteToSavedPhotosAlbum(image, self, @selector(xhs_image:didFinishSavingWithError:contextInfo:), nil);
                                } else {
                                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                                        [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:data options:nil];
                                    } completionHandler:^(BOOL success, NSError *error) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [self xhs_showToast:success ? @"已保存到相册" : @"保存失败"];
                                        });
                                    }];
                                }
                            } else {
                                [self xhs_showToast:@"保存失败"];
                            }
                        });
                    });
                    return;
                }
            } @catch (NSException *e) {}
        }
        responder = [responder nextResponder];
    }
    [self xhs_showToast:@"保存失败"];
}

%new
- (UIImageView *)xhs_findImageViewInView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([NSStringFromClass([subview class]) containsString:@"MemeImageView"] ||
            [NSStringFromClass([subview class]) containsString:@"AnimatedImageView"]) {
            if ([subview isKindOfClass:[UIImageView class]] && ((UIImageView *)subview).image) {
                return (UIImageView *)subview;
            }
        }
        UIImageView *found = [self xhs_findImageViewInView:subview];
        if (found) return found;
    }
    return nil;
}

%new
- (void)xhs_image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    [self xhs_showToast:error ? @"保存失败" : @"已保存到相册"];
}

%new
- (void)xhs_showToast:(NSString *)message {
    UIWindow *window = nil;
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            for (UIWindow *w in scene.windows) {
                if (w.isKeyWindow) { window = w; break; }
            }
        }
        if (window) break;
    }
    if (!window) window = [UIApplication sharedApplication].windows.firstObject;
    if (!window) return;
    
    [[window viewWithTag:88889] removeFromSuperview];
    
    UILabel *toast = [[UILabel alloc] init];
    toast.tag = 88889;
    toast.text = message;
    toast.textColor = [UIColor whiteColor];
    toast.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.font = [UIFont systemFontOfSize:14];
    toast.layer.cornerRadius = 8;
    toast.clipsToBounds = YES;
    [toast sizeToFit];
    toast.frame = CGRectMake(0, 0, toast.frame.size.width + 32, 40);
    toast.center = CGPointMake(window.bounds.size.width / 2, window.bounds.size.height / 2);
    [window addSubview:toast];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{ toast.alpha = 0; } completion:^(BOOL finished) { [toast removeFromSuperview]; }];
    });
}

%end


#pragma mark - 图片浏览器 URL 缓存

%hook _TtC11XYNoteBasic11IBViewModel

- (id)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    id cell = %orig;
    @try {
        NSString *noteId = [cell valueForKey:@"noteId"];
        long long index = indexPath.item;
        
        if (noteId) {
            NSString *cacheKey = [NSString stringWithFormat:@"%@_%lld", noteId, index];
            NSMutableDictionary *cacheEntry = [NSMutableDictionary dictionary];
            
            NSURL *url = [cell valueForKey:@"url"];
            if (url) cacheEntry[@"url"] = url;
            
            id asset = [cell valueForKey:@"asset"];
            if (asset) {
                NSURL *livePhotoVideoURL = [asset valueForKey:@"livePhotoVideoURL"];
                NSURL *livePhotoImageURL = [asset valueForKey:@"livePhotoImageURL"];
                if (livePhotoVideoURL) cacheEntry[@"livePhotoVideoURL"] = livePhotoVideoURL;
                if (livePhotoImageURL) cacheEntry[@"livePhotoImageURL"] = livePhotoImageURL;
            }
            
            if (cacheEntry.count > 0) imageUrlCache[cacheKey] = cacheEntry;
        }
    } @catch (NSException *e) {}
    return cell;
}

%end

#pragma mark - 批量下载按钮

%hook _TtC11XYNoteBasic14IBNumIndicator

- (void)didMoveToSuperview {
    %orig;
    if ([self superview]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self xhs_addDownloadButtons];
        });
    }
}

%new
- (void)xhs_addDownloadButtons {
    UIView *superview = [self superview];
    if (!superview || [superview viewWithTag:77777]) return;
    
    UIView *btnContainer = [[UIView alloc] init];
    btnContainer.tag = 77777;
    
    CGFloat btnSize = 24;
    CGFloat spacing = 8;
    
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightMedium];
    
    // 单张下载
    UIButton *saveOneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    saveOneBtn.tag = 77778;
    saveOneBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    saveOneBtn.layer.cornerRadius = btnSize / 2;
    saveOneBtn.clipsToBounds = YES;
    [saveOneBtn setImage:[UIImage systemImageNamed:@"square.and.arrow.down" withConfiguration:config] forState:UIControlStateNormal];
    saveOneBtn.tintColor = [UIColor whiteColor];
    [saveOneBtn addTarget:self action:@selector(xhs_saveCurrentImage) forControlEvents:UIControlEventTouchUpInside];
    
    // 全部下载
    UIButton *saveAllBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    saveAllBtn.tag = 77779;
    saveAllBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    saveAllBtn.layer.cornerRadius = btnSize / 2;
    saveAllBtn.clipsToBounds = YES;
    [saveAllBtn setImage:[UIImage systemImageNamed:@"square.and.arrow.down.on.square" withConfiguration:config] forState:UIControlStateNormal];
    saveAllBtn.tintColor = [UIColor whiteColor];
    [saveAllBtn addTarget:self action:@selector(xhs_saveAllImages) forControlEvents:UIControlEventTouchUpInside];
    
    [btnContainer addSubview:saveOneBtn];
    [btnContainer addSubview:saveAllBtn];
    [superview addSubview:btnContainer];
    
    CGFloat margin = 10;
    CGFloat containerWidth = btnSize * 2 + spacing;
    CGFloat superHeight = superview.bounds.size.height;
    
    btnContainer.frame = CGRectMake(margin, superHeight - btnSize - margin, containerWidth, btnSize);
    saveOneBtn.frame = CGRectMake(0, 0, btnSize, btnSize);
    saveAllBtn.frame = CGRectMake(btnSize + spacing, 0, btnSize, btnSize);
}

%new
- (void)xhs_saveCurrentImage {
    id imageBrowser = [self xhs_findImageBrowser];
    if (!imageBrowser) {
        [self xhs_showToast:@"无法获取图片"];
        return;
    }
    
    Ivar ivar = class_getInstanceVariable([imageBrowser class], "displayIndex");
    long long currentIndex = 0;
    if (ivar) currentIndex = *(long long *)((char *)(__bridge void *)imageBrowser + ivar_getOffset(ivar));
    if (currentIndex < 0) currentIndex = 0;
    
    [self xhs_saveImageAtIndex:currentIndex showToast:YES];
}


%new
- (void)xhs_saveAllImages {
    id imageBrowser = [self xhs_findImageBrowser];
    if (!imageBrowser) {
        [self xhs_showToast:@"无法获取图片"];
        return;
    }
    
    UICollectionView *collection = [imageBrowser valueForKey:@"collection"];
    if (!collection) {
        [self xhs_showToast:@"无法获取图片"];
        return;
    }
    
    long long amount = [collection numberOfItemsInSection:0];
    if (amount <= 0) {
        [self xhs_showToast:@"无图片可保存"];
        return;
    }
    
    NSString *noteId = nil;
    @try {
        NSIndexPath *firstIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        UICollectionViewCell *firstCell = [collection cellForItemAtIndexPath:firstIndexPath];
        if (firstCell) noteId = [firstCell valueForKey:@"noteId"];
    } @catch (NSException *e) {}
    
    UILabel *progressToast = [self xhs_createProgressToast];
    progressToast.text = [NSString stringWithFormat:@"正在保存 0/%lld...", amount];
    
    __block long long savedCount = 0;
    __block long long failedCount = 0;
    __block long long processedCount = 0;
    
    dispatch_queue_t saveQueue = dispatch_queue_create("com.xhs.batchsave", DISPATCH_QUEUE_SERIAL);
    
    for (long long i = 0; i < amount; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * 0.5 * NSEC_PER_SEC)), saveQueue, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                progressToast.text = [NSString stringWithFormat:@"正在保存 %lld/%lld...", processedCount + 1, amount];
                [progressToast sizeToFit];
                CGRect frame = progressToast.frame;
                frame.size.width = progressToast.frame.size.width + 32;
                frame.size.height = 40;
                progressToast.frame = frame;
                UIWindow *window = progressToast.superview ? (UIWindow *)progressToast.superview : nil;
                if (window) progressToast.center = CGPointMake(window.bounds.size.width / 2, window.bounds.size.height / 2);
                
                [self xhs_saveImageAtIndex:i noteId:noteId completion:^(BOOL success) {
                    processedCount++;
                    if (success) savedCount++; else failedCount++;
                    
                    if (processedCount == amount) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            progressToast.text = (failedCount == 0) 
                                ? [NSString stringWithFormat:@"已保存 %lld 张图片", savedCount]
                                : [NSString stringWithFormat:@"保存完成: %lld 成功, %lld 失败", savedCount, failedCount];
                            [progressToast sizeToFit];
                            CGRect frame = progressToast.frame;
                            frame.size.width = progressToast.frame.size.width + 32;
                            frame.size.height = 40;
                            progressToast.frame = frame;
                            UIWindow *window = progressToast.superview ? (UIWindow *)progressToast.superview : nil;
                            if (window) progressToast.center = CGPointMake(window.bounds.size.width / 2, window.bounds.size.height / 2);
                            
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [UIView animateWithDuration:0.3 animations:^{ progressToast.alpha = 0; } completion:^(BOOL finished) { [progressToast removeFromSuperview]; }];
                            });
                        });
                    }
                }];
            });
        });
    }
}

%new
- (UILabel *)xhs_createProgressToast {
    UIWindow *window = nil;
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            for (UIWindow *w in scene.windows) {
                if (w.isKeyWindow) { window = w; break; }
            }
        }
        if (window) break;
    }
    if (!window) window = [UIApplication sharedApplication].windows.firstObject;
    if (!window) return nil;
    
    [[window viewWithTag:77780] removeFromSuperview];
    
    UILabel *toast = [[UILabel alloc] init];
    toast.tag = 77780;
    toast.textColor = [UIColor whiteColor];
    toast.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.font = [UIFont systemFontOfSize:14];
    toast.layer.cornerRadius = 8;
    toast.clipsToBounds = YES;
    toast.frame = CGRectMake(0, 0, 150, 40);
    toast.center = CGPointMake(window.bounds.size.width / 2, window.bounds.size.height / 2);
    [window addSubview:toast];
    return toast;
}

%new
- (void)xhs_saveImageAtIndex:(long long)index showToast:(BOOL)showToast {
    [self xhs_saveImageAtIndex:index noteId:nil completion:^(BOOL success) {
        if (showToast) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self xhs_showToast:success ? @"已保存到相册" : @"保存失败"];
            });
        }
    }];
}


%new
- (void)xhs_saveImageAtIndex:(long long)index noteId:(NSString *)noteId completion:(void (^)(BOOL success))completion {
    id imageBrowser = [self xhs_findImageBrowser];
    if (!imageBrowser) {
        if (completion) completion(NO);
        return;
    }
    
    @try {
        UICollectionView *collection = [imageBrowser valueForKey:@"collection"];
        if (!collection) {
            if (completion) completion(NO);
            return;
        }
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        UICollectionViewCell *cell = [collection cellForItemAtIndexPath:indexPath];
        
        // 优先从缓存读取
        if (!cell && noteId) {
            NSString *cacheKey = [NSString stringWithFormat:@"%@_%lld", noteId, index];
            NSDictionary *cachedInfo = imageUrlCache[cacheKey];
            
            if (cachedInfo) {
                NSURL *livePhotoVideoURL = cachedInfo[@"livePhotoVideoURL"];
                NSURL *livePhotoImageURL = cachedInfo[@"livePhotoImageURL"];
                NSURL *url = cachedInfo[@"url"];
                
                if (livePhotoVideoURL && (livePhotoImageURL || url)) {
                    NSURL *imageURL = livePhotoImageURL ?: url;
                    [self xhs_saveLivePhotoWithImageURL:imageURL videoURL:livePhotoVideoURL completion:completion];
                    return;
                }
                
                if (url) {
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                        NSData *data = [NSData dataWithContentsOfURL:url];
                        UIImage *img = [UIImage imageWithData:data];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (img) {
                                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
                                if (completion) completion(YES);
                            } else {
                                if (completion) completion(NO);
                            }
                        });
                    });
                    return;
                }
            }
        }
        
        // 缓存未命中，滚动获取 cell
        if (!cell) {
            [collection scrollToItemAtIndexPath:indexPath 
                               atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally 
                                       animated:NO];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self xhs_saveImageAtIndexInternal:index fromCollection:collection completion:completion];
            });
            return;
        }
        
        [self xhs_saveImageAtIndexInternal:index fromCollection:collection completion:completion];
        
    } @catch (NSException *e) {
        if (completion) completion(NO);
    }
}

%new
- (void)xhs_saveImageAtIndexInternal:(long long)index fromCollection:(UICollectionView *)collection completion:(void (^)(BOOL success))completion {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    UICollectionViewCell *cell = [collection cellForItemAtIndexPath:indexPath];
    
    if (!cell) {
        if (completion) completion(NO);
        return;
    }
    
    // 缓存 cell 信息
    @try {
        NSString *noteId = [cell valueForKey:@"noteId"];
        if (noteId) {
            NSString *cacheKey = [NSString stringWithFormat:@"%@_%lld", noteId, index];
            NSMutableDictionary *cacheEntry = [NSMutableDictionary dictionary];
            
            NSURL *url = [cell valueForKey:@"url"];
            if (url) cacheEntry[@"url"] = url;
            
            id asset = [cell valueForKey:@"asset"];
            if (asset) {
                NSURL *livePhotoVideoURL = [asset valueForKey:@"livePhotoVideoURL"];
                NSURL *livePhotoImageURL = [asset valueForKey:@"livePhotoImageURL"];
                if (livePhotoVideoURL) cacheEntry[@"livePhotoVideoURL"] = livePhotoVideoURL;
                if (livePhotoImageURL) cacheEntry[@"livePhotoImageURL"] = livePhotoImageURL;
            }
            
            if (cacheEntry.count > 0) imageUrlCache[cacheKey] = cacheEntry;
        }
    } @catch (NSException *e) {}
    
    // Live Photo
    id asset = nil;
    @try { asset = [cell valueForKey:@"asset"]; } @catch (NSException *e) {}
    
    if (asset) {
        NSURL *livePhotoVideoURL = nil;
        @try { livePhotoVideoURL = [asset valueForKey:@"livePhotoVideoURL"]; } @catch (NSException *e) {}
        
        if (livePhotoVideoURL) {
            NSURL *imageURL = nil;
            @try { imageURL = [asset valueForKey:@"livePhotoImageURL"]; } @catch (NSException *e) {}
            if (!imageURL) {
                @try { imageURL = [cell valueForKey:@"url"]; } @catch (NSException *e) {}
            }
            
            if (imageURL) {
                [self xhs_saveLivePhotoWithImageURL:imageURL videoURL:livePhotoVideoURL completion:completion];
                return;
            }
        }
    }
    
    // 普通图片
    NSURL *cellUrl = nil;
    @try { cellUrl = [cell valueForKey:@"url"]; } @catch (NSException *e) {}
    
    if (cellUrl) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSData *data = [NSData dataWithContentsOfURL:cellUrl];
            UIImage *img = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (img) {
                    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
                    if (completion) completion(YES);
                } else {
                    if (completion) completion(NO);
                }
            });
        });
        return;
    }
    
    // fallback: 从 imageView 获取
    UIImageView *imageView = [self xhs_findImageViewInView:cell];
    if (imageView && imageView.image) {
        UIImageWriteToSavedPhotosAlbum(imageView.image, nil, nil, nil);
        if (completion) completion(YES);
        return;
    }
    
    if (completion) completion(NO);
}


%new
- (void)xhs_saveLivePhotoWithImageURL:(NSURL *)imageURL videoURL:(NSURL *)videoURL completion:(void (^)(BOOL success))completion {
    NSString *tempDir = NSTemporaryDirectory();
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSString *imagePath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"xhs_lp_%@_img.jpg", uuid]];
    NSString *videoPath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"xhs_lp_%@_vid.mov", uuid]];
    NSString *outImagePath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"xhs_lp_%@_out_img.jpg", uuid]];
    NSString *outVideoPath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"xhs_lp_%@_out_vid.mov", uuid]];
    NSString *assetID = uuid;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *imageUrlStr = imageURL.absoluteString;
        if ([imageUrlStr containsString:@"format/heif"]) {
            imageUrlStr = [imageUrlStr stringByReplacingOccurrencesOfString:@"format/heif" withString:@"format/jpg"];
        }
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrlStr]];
        if (!imageData) {
            dispatch_async(dispatch_get_main_queue(), ^{ if (completion) completion(NO); });
            return;
        }
        [imageData writeToFile:imagePath atomically:YES];
        
        NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
        if (!videoData) {
            [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{ if (completion) completion(NO); });
            return;
        }
        [videoData writeToFile:videoPath atomically:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            Class mgr = NSClassFromString(@"XYPKLivePhotoManager");
            if (!mgr) {
                [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
                [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
                if (completion) completion(NO);
                return;
            }
            
            NSURL *outImgURL = [NSURL fileURLWithPath:outImagePath];
            NSURL *outVidURL = [NSURL fileURLWithPath:outVideoPath];
            
            if ([mgr convertImageToLivePhotoFormatNewWithInputImagePath:imagePath outputImageURL:outImgURL assetID:assetID] != 0) {
                [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
                [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
                if (completion) completion(NO);
                return;
            }
            
            [mgr preConvertVideoToLivePhotoFormatWithInputVideoPath:videoPath outputVideoURL:outVidURL assetID:assetID completion:^(BOOL cvtOK) {
                if (!cvtOK) {
                    NSFileManager *fm = [NSFileManager defaultManager];
                    [fm removeItemAtPath:imagePath error:nil];
                    [fm removeItemAtPath:videoPath error:nil];
                    [fm removeItemAtPath:outImagePath error:nil];
                    dispatch_async(dispatch_get_main_queue(), ^{ if (completion) completion(NO); });
                    return;
                }
                
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    PHAssetCreationRequest *req = [PHAssetCreationRequest creationRequestForAsset];
                    PHAssetResourceCreationOptions *opts = [[PHAssetResourceCreationOptions alloc] init];
                    opts.shouldMoveFile = NO;
                    [req addResourceWithType:PHAssetResourceTypePhoto fileURL:outImgURL options:opts];
                    [req addResourceWithType:PHAssetResourceTypePairedVideo fileURL:outVidURL options:opts];
                } completionHandler:^(BOOL success, NSError *error) {
                    NSFileManager *fm = [NSFileManager defaultManager];
                    [fm removeItemAtPath:imagePath error:nil];
                    [fm removeItemAtPath:videoPath error:nil];
                    [fm removeItemAtPath:outImagePath error:nil];
                    [fm removeItemAtPath:outVideoPath error:nil];
                    dispatch_async(dispatch_get_main_queue(), ^{ if (completion) completion(success); });
                }];
            }];
        });
    });
}

%new
- (UIImageView *)xhs_findImageViewInView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            UIImageView *iv = (UIImageView *)subview;
            if (iv.image && iv.image.size.width > 100) return iv;
        }
        UIImageView *found = [self xhs_findImageViewInView:subview];
        if (found) return found;
    }
    return nil;
}

%new
- (id)xhs_findImageBrowser {
    UIView *view = self;
    while (view) {
        if ([NSStringFromClass([view class]) containsString:@"ImageBrowser"]) return view;
        view = view.superview;
    }
    return nil;
}

%new
- (void)xhs_showToast:(NSString *)message {
    UIWindow *window = nil;
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            for (UIWindow *w in scene.windows) {
                if (w.isKeyWindow) { window = w; break; }
            }
        }
        if (window) break;
    }
    if (!window) window = [UIApplication sharedApplication].windows.firstObject;
    if (!window) return;
    
    [[window viewWithTag:77780] removeFromSuperview];
    
    UILabel *toast = [[UILabel alloc] init];
    toast.tag = 77780;
    toast.text = message;
    toast.textColor = [UIColor whiteColor];
    toast.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.font = [UIFont systemFontOfSize:14];
    toast.layer.cornerRadius = 8;
    toast.clipsToBounds = YES;
    [toast sizeToFit];
    toast.frame = CGRectMake(0, 0, toast.frame.size.width + 32, 40);
    toast.center = CGPointMake(window.bounds.size.width / 2, window.bounds.size.height / 2);
    [window addSubview:toast];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{ toast.alpha = 0; } completion:^(BOOL finished) { [toast removeFromSuperview]; }];
    });
}

%end


#pragma mark - 图片指示器常驻 & 手势处理

%hook _TtC11XYNoteBasic12ImageBrowser

- (void)_hidIndicator {
    // 保持指示器显示
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *touchedView = touch.view;
    while (touchedView) {
        if (touchedView.tag == 77777 || touchedView.tag == 77778 || touchedView.tag == 77779) return NO;
        touchedView = touchedView.superview;
    }
    return %orig;
}

%end

#pragma mark - 初始化

%ctor {
    @autoreleasepool {
        livePhotoUrlCache = [NSMutableDictionary dictionary];
        commentLivePhotoCache = [NSMutableDictionary dictionary];
        imageUrlCache = [NSMutableDictionary dictionary];
        showCopyrightAnimation();
    }
}
