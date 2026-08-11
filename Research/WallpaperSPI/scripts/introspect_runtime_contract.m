#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <objc/runtime.h>

static NSString *const FrameworkPath =
    @"/System/Library/PrivateFrameworks/WallpaperExtensionKit.framework/Versions/A/WallpaperExtensionKit";

static NSString *SafeUTF8(const char *value) {
  return value ? [NSString stringWithUTF8String:value] : @"<nil>";
}

@interface RecordingDecoder : NSCoder
@property(nonatomic, readonly) NSMutableArray<NSDictionary *> *records;
@end

@implementation RecordingDecoder {
  NSMutableArray<NSDictionary *> *_records;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _records = [NSMutableArray array];
  }
  return self;
}

- (NSMutableArray<NSDictionary *> *)records {
  return _records;
}

- (BOOL)allowsKeyedCoding {
  return YES;
}

- (BOOL)requiresSecureCoding {
  return YES;
}

- (id)decodeObjectOfClass:(Class)class forKey:(NSString *)key {
  [_records addObject:@{
    @"operation" : @"decodeObjectOfClass",
    @"class" : NSStringFromClass(class) ?: @"<nil>",
    @"key" : key ?: @"<nil>"
  }];
  return nil;
}

- (id)decodeObjectOfClasses:(NSSet<Class> *)classes forKey:(NSString *)key {
  NSMutableArray<NSString *> *names = [NSMutableArray array];
  for (Class class in classes) {
    [names addObject:NSStringFromClass(class) ?: @"<nil>"];
  }
  [names sortUsingSelector:@selector(compare:)];
  [_records addObject:@{
    @"operation" : @"decodeObjectOfClasses",
    @"classes" : names,
    @"key" : key ?: @"<nil>"
  }];
  return nil;
}

- (NSArray *)decodeArrayOfObjectsOfClasses:(NSSet<Class> *)classes
                                    forKey:(NSString *)key {
  NSMutableArray<NSString *> *names = [NSMutableArray array];
  for (Class class in classes) {
    [names addObject:NSStringFromClass(class) ?: @"<nil>"];
  }
  [names sortUsingSelector:@selector(compare:)];
  [_records addObject:@{
    @"operation" : @"decodeArrayOfObjectsOfClasses",
    @"classes" : names,
    @"key" : key ?: @"<nil>"
  }];
  return @[];
}

- (id)decodeObjectForKey:(NSString *)key {
  [_records addObject:@{
    @"operation" : @"decodeObject",
    @"key" : key ?: @"<nil>"
  }];
  return nil;
}

- (BOOL)decodeBoolForKey:(NSString *)key {
  [_records addObject:@{ @"operation" : @"decodeBool", @"key" : key ?: @"<nil>" }];
  return NO;
}

- (NSInteger)decodeIntegerForKey:(NSString *)key {
  [_records addObject:@{ @"operation" : @"decodeInteger", @"key" : key ?: @"<nil>" }];
  return 0;
}

- (int64_t)decodeInt64ForKey:(NSString *)key {
  [_records addObject:@{ @"operation" : @"decodeInt64", @"key" : key ?: @"<nil>" }];
  return 0;
}

- (double)decodeDoubleForKey:(NSString *)key {
  [_records addObject:@{ @"operation" : @"decodeDouble", @"key" : key ?: @"<nil>" }];
  return 0;
}

- (float)decodeFloatForKey:(NSString *)key {
  [_records addObject:@{ @"operation" : @"decodeFloat", @"key" : key ?: @"<nil>" }];
  return 0;
}

@end

static NSArray<NSDictionary *> *IvarRecords(Class class) {
  unsigned int count = 0;
  Ivar *ivars = class_copyIvarList(class, &count);
  NSMutableArray<NSDictionary *> *records = [NSMutableArray array];
  for (unsigned int index = 0; index < count; index++) {
    Ivar ivar = ivars[index];
    [records addObject:@{
      @"name" : SafeUTF8(ivar_getName(ivar)),
      @"offset" : @(ivar_getOffset(ivar)),
      @"encoding" : SafeUTF8(ivar_getTypeEncoding(ivar))
    }];
  }
  free(ivars);
  return records;
}

static NSArray<NSDictionary *> *MethodRecords(Class class) {
  unsigned int count = 0;
  Method *methods = class_copyMethodList(class, &count);
  NSMutableArray<NSDictionary *> *records = [NSMutableArray array];
  for (unsigned int index = 0; index < count; index++) {
    Method method = methods[index];
    [records addObject:@{
      @"selector" : NSStringFromSelector(method_getName(method)),
      @"encoding" : SafeUTF8(method_getTypeEncoding(method))
    }];
  }
  free(methods);
  [records sortUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
    return [left[@"selector"] compare:right[@"selector"]];
  }];
  return records;
}

static NSDictionary *InspectClass(NSString *name) {
  Class class = NSClassFromString(name);
  if (!class) {
    return @{ @"class" : name, @"available" : @NO };
  }

  RecordingDecoder *decoder = [[RecordingDecoder alloc] init];
  NSString *resultName = @"not-called";
  NSString *exceptionName = nil;
  NSString *exceptionReason = nil;
  id instance = class_createInstance(class, 0);

  @try {
    if ([instance respondsToSelector:@selector(initWithCoder:)]) {
      id result = [instance initWithCoder:decoder];
      resultName = result ? NSStringFromClass([result class]) : @"nil";
    }
  } @catch (NSException *exception) {
    resultName = @"exception";
    exceptionName = exception.name;
    exceptionReason = exception.reason;
  }

  NSMutableDictionary *record = [@{
    @"class" : name,
    @"available" : @YES,
    @"instanceSize" : @(class_getInstanceSize(class)),
    @"ivars" : IvarRecords(class),
    @"methods" : MethodRecords(class),
    @"decodeRequests" : decoder.records,
    @"initWithCoderResult" : resultName
  } mutableCopy];
  if (exceptionName) {
    record[@"exceptionName"] = exceptionName;
  }
  if (exceptionReason) {
    record[@"exceptionReason"] = exceptionReason;
  }
  return record;
}

int main(void) {
  @autoreleasepool {
    void *handle = dlopen(FrameworkPath.UTF8String, RTLD_NOW | RTLD_LOCAL);
    if (!handle) {
      fprintf(stderr, "dlopen failed: %s\n", dlerror());
      return 1;
    }

    NSArray<NSString *> *targets = @[
      @"WallpaperCreationRequestXPC",
      @"WallpaperUpdateRequestXPC",
      @"WallpaperRemoteContextXPC",
      @"WallpaperSnapshotXPC",
      @"WallpaperExtensionChoiceRequestXPC",
      @"WallpaperChoiceRequestAdditionResultXPC"
    ];
    NSMutableArray<NSDictionary *> *classes = [NSMutableArray array];
    for (NSString *target in targets) {
      [classes addObject:InspectClass(target)];
    }

    NSDictionary *output = @{
      @"frameworkPath" : FrameworkPath,
      @"classes" : classes
    };
    NSError *error = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:output
                                                   options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys
                                                     error:&error];
    if (!json) {
      fprintf(stderr, "JSON encoding failed: %s\n", error.localizedDescription.UTF8String);
      dlclose(handle);
      return 1;
    }
    fwrite(json.bytes, 1, json.length, stdout);
    fputc('\n', stdout);
    dlclose(handle);
  }
  return 0;
}
