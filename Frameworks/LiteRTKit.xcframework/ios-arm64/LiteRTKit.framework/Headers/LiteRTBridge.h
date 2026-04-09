#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^LiteRTStreamChunkHandler)(NSString *chunk, BOOL isFinal, NSError * _Nullable error);

@interface LiteRTBridge : NSObject

- (void)loadModelAtPath:(NSString *)path error:(NSError * _Nullable * _Nullable)error;
- (void)loadModelAtPath:(NSString *)path backend:(NSString *)backend error:(NSError * _Nullable * _Nullable)error;
- (NSString *)generate:(NSString *)prompt error:(NSError * _Nullable * _Nullable)error;
- (void)generateStream:(NSString *)prompt onChunk:(LiteRTStreamChunkHandler)handler error:(NSError * _Nullable * _Nullable)error;
- (void)cancelGeneration;
- (void)resetSession;

@end

NS_ASSUME_NONNULL_END
