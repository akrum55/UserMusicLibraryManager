//
//  FlacTagsWrapper.h
//  UserMusicLibraryManager
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Provides FLAC front-cover image data via TagLib’s C++ API
@interface FlacTagsWrapper : NSObject

/// Returns the front-cover image data for a FLAC file at filePath, or nil
+ (nullable NSData *)frontCoverImageDataFromPath:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
