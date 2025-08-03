

//
//  FlacTagsWrapper.mm
//  UserMusicLibraryManager
//
#import "FlacTagsWrapper.h"
#import <Foundation/Foundation.h>
#import <taglib/flac/flacfile.h>
#import <taglib/toolkit/tlist.h>


@implementation FlacTagsWrapper

+ (NSData *)frontCoverImageDataFromPath:(NSString *)filePath {
    std::string path = [filePath UTF8String];
    TagLib::FLAC::File flacFile(path.c_str());
    if (!flacFile.isValid()) {
        return nil;
    }

    auto pictures = flacFile.pictureList();
    for (auto pic : pictures) {
        if (pic->type() == TagLib::FLAC::Picture::FrontCover) {
            TagLib::ByteVector data = pic->data();
            return [NSData dataWithBytes:data.data() length:data.size()];
        }
    }
    return nil;
}

@end
