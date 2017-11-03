//
//  do_Storage_SM.m
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Storage_SM.h"

#import "doIScriptEngine.h"
#import "doIApp.h"
#import "doIDataFS.h"
#import "doInvokeResult.h"
#import "doIScriptEngine.h"
#import "doZipArchive.h"
#import "doIOHelper.h"
#import "doJsonHelper.h"
#import "doILogEngine.h"
#import "doServiceContainer.h"
#import "doIAppSecurity.h"
#import <UIKit/UIKit.h>

static NSString *usedDir = @"data://";
static NSString *securityDir = @"data://security/";
static NSString *unusedDir = @"initdata://";

@implementation do_Storage_SM
#pragma mark - 方法
#pragma mark - 同步异步方法的实现
#pragma mark - exception
- (BOOL)isValidateException:(NSString *)path :(BOOL)isSecurity :(NSString *)title
{
    BOOL is = YES;
    if ([path hasPrefix:unusedDir]) {
        is = NO;
        [NSException raise:@"doStorage" format:@"%@目录下文件不能用doStorage操作",unusedDir];
    }else{
        if (!path || path.length==0) {
            is = NO;
            [NSException raise:@"doStorage" format:@"%@不能为空",title];
        }
        if (![path hasPrefix:usedDir]){
            [NSException raise:@"doStorage" format:@"%@参数只支持%@",title,usedDir];
        }else{
            if ([path hasPrefix:securityDir] && !isSecurity){
                [NSException raise:@"doStorage" format:@"%@只能read、write",securityDir];
            }
        }
    }
    return is;
}

#pragma mark - gets
- (void)getFiles:(NSArray*) parms
{
    [self gets:parms :@"file"];
}

- (void)getDirs:(NSArray*) parms
{
    [self gets:parms :@"dir"];
}

- (void)gets:(NSArray*) parms :(NSString *)type
{
    NSDictionary* _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    NSString* _callbackFuncName = [parms objectAtIndex:2];
    doInvokeResult * _invokeResult = [[doInvokeResult alloc ] init:self.UniqueKey];
    NSString * directory =[doJsonHelper GetOneText: _dictParas :@"path" :@""];
    if(directory == nil) directory = @"";
    if (![self isValidateException:directory :YES :@""]) {
        [_invokeResult SetResultArray:[NSMutableArray array]];
    }else{
        @try{
            NSString * _dirFullPath = [_scriptEngine.CurrentApp.DataFS GetFileFullPathByName:directory];
            NSMutableArray * _listAppFiles = [[NSMutableArray alloc] init];
            NSArray * dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_dirFullPath error:nil];
            for (NSString * aPath in dirs) {
                NSString * fullPath = [_dirFullPath stringByAppendingPathComponent:aPath];
                BOOL isDir;
                BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir];
                if ([type isEqualToString:@"file"]) {
                    if(isExist && !isDir){
                        [_listAppFiles addObject:aPath];
                    }
                }else
                    if(isExist && isDir){
                        NSString *returnValue = [NSString stringWithFormat:@"/%@",aPath];
                        [_listAppFiles addObject:returnValue];
                    }
                
            }
            [_invokeResult SetResultArray:_listAppFiles];
        }@catch (NSException * ex){
            [_invokeResult SetException:ex];
        }@finally {
            
        }
    }
    [_scriptEngine Callback:_callbackFuncName :_invokeResult];
}


#pragma mark - delete
- (void)deleteDir:(NSArray*) parms
{
    [self delete:parms :@"dir"];
}

- (void)deleteFile:(NSArray*)parms
{
    [self delete:parms :@"file"];
}

- (void)delete:(NSArray*)parms :(NSString *)type
{
    NSDictionary* _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    NSString* _callbackFuncName = [parms objectAtIndex:2];
    doInvokeResult * _invokeResult = [[doInvokeResult alloc ] init:self.UniqueKey];
    NSString * directory = [doJsonHelper GetOneText: _dictParas :@"path" :@""];
    if(directory == nil) directory = @"";
    
    @try {
        [self isValidateException:directory :YES :@""];
        NSString * _dirFullPath = [_scriptEngine.CurrentApp.DataFS GetFileFullPathByName:directory];
        BOOL isExist;
        if ([type isEqualToString:@"dir"]) {
            isExist = [doIOHelper ExistDirectory:_dirFullPath];
        }else
            isExist = [doIOHelper ExistFile:_dirFullPath];
        if(!isExist){
            [_invokeResult SetResultBoolean:YES];
        }else{
            BOOL bResult = [[NSFileManager defaultManager] removeItemAtPath:_dirFullPath error:nil];
            [_invokeResult SetResultBoolean:bResult];
        }
    }
    @catch (NSException *exception) {
        [_invokeResult SetResultBoolean:NO];
    }
    @finally {
        [_scriptEngine Callback:_callbackFuncName :_invokeResult];
    }
}


#pragma mark - exist
- (void)dirExist:(NSArray*) parms
{
    [self exist:parms :@"dir"];
}

- (void)fileExist:(NSArray*) parms
{
    [self exist:parms :@"file"];
}

- (void)exist:(NSArray*)parms :(NSString *)type
{
    NSDictionary* _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    doInvokeResult * _invokeResult = [parms objectAtIndex:2];
    NSString * _filename = [doJsonHelper GetOneText: _dictParas :@"path" :@""];
    if(_filename == nil) _filename = @"";
    NSString * _fileFullPath = [_scriptEngine.CurrentApp.DataFS GetFileFullPathByName:_filename];
    BOOL _exist;
    if (![self isValidateException:_filename :YES :@""]) {
        _exist = NO;
    }else{
        if ([type isEqualToString:@"dir"]) {
            _exist = [doIOHelper ExistDirectory:_fileFullPath];
        }else
            _exist = [doIOHelper ExistFile:_fileFullPath];
    }
    [_invokeResult SetResultBoolean:_exist];
}

#pragma mark - read
- (void)readFileSync:(NSArray *)parms
{
    [self readContent:parms :YES];
}
- (void)readFile:(NSArray*) parms
{
    [self readContent:parms :NO];
}
- (void)readContent:(NSArray*) parms :(BOOL)isSync
{
    NSDictionary* _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    
    doInvokeResult * _invokeResult ;
    NSString* _callbackFuncName;
    
    if (isSync) {
        _invokeResult = [parms objectAtIndex:2];
    }else{
        _callbackFuncName = [parms objectAtIndex:2];
        _invokeResult = [[doInvokeResult alloc ] init:self.UniqueKey];
    }
    
    BOOL isSecurity = [doJsonHelper GetOneBoolean:_dictParas :@"isSecurity" :NO];
    NSStringEncoding encode = NSUTF8StringEncoding;
    NSString *encoding = [doJsonHelper GetOneText:_dictParas :@"encoding" :@"utf-8"];
    if ([[encoding lowercaseString] isEqualToString:@"gbk"]) {
        encode = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    }

    NSString * _filename = [doJsonHelper GetOneText: _dictParas :@"path" :@""];
    if (![self isValidateException:_filename :YES :@""]) {
        if (isSync) {
            [_invokeResult SetResultText:@""];
        }else{
            [_invokeResult SetResultText:@""];
            [_scriptEngine Callback:_callbackFuncName :_invokeResult];
        }
        return;
    }
    
    if(_filename == nil) _filename = @"";
    NSString * blockFilename = _filename;
    blockFilename = [_scriptEngine.CurrentApp.DataFS GetFileFullPathByName:_filename];
    NSString *content = [self getFileContent:blockFilename :_filename :isSecurity :encode];
    
    if (isSync) {
        [_invokeResult SetResultText:content];
    }else{
        [_invokeResult SetResultText:content];
        [_scriptEngine Callback:_callbackFuncName :_invokeResult];
    }
}
- (NSString *)getFileContent:(NSString *)filename :(NSString *)path :(BOOL)isSecurity :(NSStringEncoding)encode
{
    @try{
        NSError *error;
        NSString * _content = @"";
        if ([doIOHelper ExistFile:filename]) {
            id<doIAppSecurity> appSecurity = [doServiceContainer Instance].AppSecurity;
            if ([appSecurity.appVersion isEqualToString:@"debug"]) {
                _content = [NSString stringWithContentsOfFile:filename encoding:encode error:&error];
                if (_content == nil) {
                    if (encode == NSUTF8StringEncoding) { // utf-8编码
                        [[doServiceContainer Instance].LogEngine WriteError:nil :@"读取的文件不是以utf-8格式编码"];
                    }else { // gbk编码
                        [[doServiceContainer Instance].LogEngine WriteError:nil :@"读取的文件不是以gbk格式编码"];
                    }
                }
            }else{
                NSString *datakey = [appSecurity getDataKey];
                if ([datakey isEqualToString:@"datakeyios"] || !datakey) {
                    datakey = @"";
                }
                BOOL _is = YES;
                if(datakey.length > 0)
                {
                    if ([path hasPrefix:securityDir]) {
                        _is = YES;
                    }else
                        _is = isSecurity;
                }else{
                    _is = NO;
                }
                if (_is) {
                    _content = [[NSString alloc] initWithData:[doIOHelper DecryptFile:filename :datakey] encoding:encode];
                }else
                    _content = [NSString stringWithContentsOfFile:filename encoding:encode error:nil];
            }
        }
        return _content;
    }
    @catch(NSException * ex)
    {
        doInvokeResult* _result = [[doInvokeResult alloc]init];
        [_result SetException:ex];
        return nil;
    }
}

#pragma mark - write
- (void)writeFile:(NSArray*) parms
{
    NSDictionary* _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    NSString* _callbackFuncName = [parms objectAtIndex:2];
    doInvokeResult * _invokeResult = [[doInvokeResult alloc ] init:self.UniqueKey];
    NSString * _filename = [doJsonHelper GetOneText: _dictParas :@"path" :@""];
    NSString * _datacontent = [doJsonHelper GetOneText: _dictParas :@"data" :@""];
    BOOL isSecurity = [doJsonHelper GetOneBoolean:_dictParas :@"isSecurity" :NO];
    NSString *encoding = [doJsonHelper GetOneText:_dictParas :@"encoding" :@"utf-8"];
    BOOL isAppend = [doJsonHelper GetOneBoolean:_dictParas :@"isAppend" :NO];
    NSStringEncoding encode = NSUTF8StringEncoding;
    if ([[encoding lowercaseString] isEqualToString:@"gbk"]) {
        encode = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    }

    if(_filename == nil) _filename = @"";
    NSString * blockFilename = _filename;
    
    @try{
        [self isValidateException:_filename :YES :@""];
        blockFilename = [_scriptEngine.CurrentApp.DataFS GetFileFullPathByName:_filename];
        NSString* _path =[blockFilename stringByDeletingLastPathComponent] ;
        if(![[NSFileManager defaultManager] fileExistsAtPath:_path])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath: _path withIntermediateDirectories:YES attributes:nil error:nil];
        }
        id<doIAppSecurity> appSecurity = [doServiceContainer Instance].AppSecurity;
        if ([appSecurity.appVersion isEqualToString:@"debug"]) {
            [self writeToFile:blockFilename :_datacontent :encode :isAppend];
        }else{
            NSString *datakey = [appSecurity getDataKey];
            if ([datakey isEqualToString:@"datakeyios"] || !datakey) {
                datakey = @"";
            }
            BOOL _is = YES;
            if(datakey.length > 0)
            {
                if ([_filename hasPrefix:securityDir]) {
                    _is = YES;
                }else{
                    _is = isSecurity;
                }
            }else{
                _is = NO;
            }
            if (_is) {
                [doIOHelper EncryptFile:blockFilename :_datacontent :datakey :encode];
            }else{
                if (![doIOHelper ExistDirectory:_path]) {
                    [doIOHelper CreateDirectory:_path];
                }
                [self writeToFile:blockFilename :_datacontent :encode :isAppend];
            }
        }
        
        [_invokeResult SetResultBoolean:YES];
    }@catch(NSException * ex){
        [_invokeResult SetResultBoolean:NO];
    }@finally{
        [_scriptEngine Callback:_callbackFuncName :_invokeResult];
    }
}

- (void)writeToFile:(NSString *)file :(NSString *)content :(NSStringEncoding)encode  :(BOOL)isAppend
{
    if (!isAppend) {
        [content writeToFile:file atomically:YES encoding:encode error:nil];
        return;
    }
    if (![doIOHelper ExistFile:file]) {
        
        [@"" writeToFile:file atomically:YES encoding:encode error:nil];
    }
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:file];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[content dataUsingEncoding:encode]];
    [fileHandle closeFile];
}

#pragma mark - copy
- (void)copy:(NSArray*) parms
{
    NSDictionary* _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    NSString* _callbackFuncName = [parms objectAtIndex:2];
    doInvokeResult * _invokeResult = [[doInvokeResult alloc ] init:self.UniqueKey];
    // 压缩后文件的名称 (包含路径)
    NSString *_target = [doJsonHelper GetOneText: _dictParas :@"target" :@""];
    // 要进行压缩的源文件路径
    NSArray *_source = [doJsonHelper GetOneArray:_dictParas :@"source"];
    NSMutableArray* _sourceFull = [[NSMutableArray alloc]init];
    
    @try {
        [self isValidateException:_target :YES :@"target"];
        if (_source.count<=0) {
            [NSException raise:@"doStorage" format:@"copy的source参数不能为空"];
        }
        _target = [_scriptEngine.CurrentApp.DataFS GetFileFullPathByName:_target];
        if(![doIOHelper ExistDirectory:_target])
            [doIOHelper CreateDirectory:_target];
        for(int i = 0;i<_source.count;i++)
        {
            [self isValidateException:_source[i] :YES :@"source"];
            
            if(_source[i]!=nil)
            {
                NSString* _temp = [_scriptEngine.CurrentApp.DataFS GetFileFullPathByName:_source[i]];
                BOOL isDir;
                //目录
                if([[NSFileManager defaultManager] fileExistsAtPath:_temp isDirectory:&isDir] && isDir){
                    [_sourceFull addObject:_temp];
                }
                else
                {
                    //文件
                    if (![doIOHelper ExistFile:_temp]) {
                        continue;
                    }
                    if(_temp!=nil)
                        [_sourceFull addObject:_temp];
                }
            }
        }
        if (_sourceFull.count > 0) {//更新后删除的情况
            for(int i = 0;i<_sourceFull.count;i++)
            {
                BOOL isDir;
                //目录
                if([[NSFileManager defaultManager] fileExistsAtPath:_sourceFull[i] isDirectory:&isDir] && isDir){
                    [doIOHelper DirectoryCopy:_sourceFull[i] :_target];
                }
                else
                {
                    NSString* file = [_sourceFull[i] lastPathComponent];
                    NSString* targetFile =[NSString stringWithFormat:@"%@/%@",_target,file];
                    [doIOHelper FileCopy:_sourceFull[i] : targetFile];
                }
            }
            
            [_invokeResult SetResultBoolean:YES];
        }
        else
        {
            [_invokeResult SetResultBoolean:NO];
        }
        
    }
    @catch (NSException *exception) {
        [_invokeResult SetException:exception];
    }
    
    [_scriptEngine Callback:_callbackFuncName :_invokeResult];
}
- (void)copyFile:(NSArray *)parms
{
    NSDictionary* _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    NSString* _callbackFuncName = [parms objectAtIndex:2];
    doInvokeResult * _invokeResult = [[doInvokeResult alloc ] init:self.UniqueKey];
    NSString *_target = [doJsonHelper GetOneText: _dictParas :@"target" :@""];
    NSString *_source = [doJsonHelper GetOneText:_dictParas :@"source" :@""];
    
    @try {
        [self isValidateException:_target :YES :@"target"];
        [self isValidateException:_source :YES :@"source"];
        
        _target = [_scriptEngine.CurrentApp.DataFS GetFileFullPathByName:_target];
        NSString *_targetFileDic = [_target stringByDeletingLastPathComponent];
        if (![doIOHelper ExistDirectory:_targetFileDic]) {
            [doIOHelper CreateDirectory:_targetFileDic];
        }
        NSString *_sourcePath = [_scriptEngine.CurrentApp.DataFS GetFileFullPathByName:_source];
        if (![doIOHelper ExistFile:_sourcePath]) {
            [_invokeResult SetResultBoolean:NO];
        }else{
            [doIOHelper FileCopy:_sourcePath : _target];
            [_invokeResult SetResultBoolean:YES];
        }
    }
    @catch (NSException *exception) {
        [_invokeResult SetResultBoolean:NO];
    }
    @finally {
        [_scriptEngine Callback:_callbackFuncName :_invokeResult];
    }
}


#pragma mark - zip
- (void)zip:(NSArray *)parms
{
    [self zipFiles:parms :@"zip"];
}
- (void)zipFiles:(NSArray *)parms
{
    [self zipFiles:parms :@"zipFiles"];
}
- (void)zipFiles:(NSArray *)parms :(NSString *)type
{
    NSDictionary* _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    NSString* _callbackFuncName = [parms objectAtIndex:2];
    doInvokeResult * _invokeResult = [[doInvokeResult alloc ] init:self.UniqueKey];
    
    // 压缩后文件的名称 (包含路径)
    NSString *_target = [doJsonHelper GetOneText: _dictParas :@"target" :@""];
    // 要进行压缩的源文件路径
    NSArray * _sources;
    if ([type isEqualToString:@"zipFiles"]) {
        _sources = [doJsonHelper GetOneArray: _dictParas :@"source"];
    }else{
        NSString *s = [doJsonHelper GetOneText: _dictParas :@"source" :@""];
        _sources = @[s];
    }
    
    @try {
        [self isValidateException:_target :YES :@"target"];
        
        if (_sources==nil||_sources.count<=0) {
            [NSException raise:@"doStorage" format:@"zipFiles的source参数不能为空"];
        }
        
        _target = [_scriptEngine.CurrentApp.DataFS GetFileFullPathByName:_target];
        NSString *str = [_target stringByDeletingLastPathComponent];
        if(![[NSFileManager defaultManager] fileExistsAtPath:str ])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:str withIntermediateDirectories:YES attributes:nil error:nil];
        }
        doZipArchive *za = [[doZipArchive alloc] init];
        [za CreateZipFile2:_target];
        BOOL fileExistsAtPath;
        int i = 0;
        for(NSString* _source in _sources){
            [self isValidateException:_source :YES :@"source"];
            
            NSString* source = [_scriptEngine.CurrentApp.DataFS GetFileFullPathByName:_source];
            BOOL isDirectory;
            fileExistsAtPath = [[NSFileManager defaultManager] fileExistsAtPath:source isDirectory:&isDirectory];
            if(fileExistsAtPath){
                if(isDirectory)
                    [za addFolderToZip:source pathPrefix:nil];
                else
                    [za addFileToZip:source newname:[source lastPathComponent]];
            }else
                i++;
        }
        if(_sources.count==1 && !fileExistsAtPath){
            [_invokeResult SetResultBoolean:NO];
        }else{
            BOOL success = [za CloseZipFile2];
            if (i==_sources.count) {
                [_invokeResult SetResultBoolean:NO];
            }else
                [_invokeResult SetResultBoolean:success];
        }
    }
    @catch (NSException *exception) {
        [_invokeResult SetException:exception];
    }
    @finally {
        [_scriptEngine Callback:_callbackFuncName :_invokeResult];
    }
}
- (void)unzip:(NSArray*) parms
{
    NSDictionary* _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    NSString* _callbackFuncName = [parms objectAtIndex:2];
    doInvokeResult * _invokeResult = [[doInvokeResult alloc ] init:self.UniqueKey];
    // 压缩后文件的名称 (包含路径)
    NSString *_target = [doJsonHelper GetOneText: _dictParas :@"target" :@""];
    // 要进行压缩的源文件路径
    NSString * _source = [doJsonHelper GetOneText: _dictParas :@"source" :@""];
    
    @try {
        [self isValidateException:_target :YES :@"target"];
        [self isValidateException:_source :YES :@"source"];
        
        _target = [_scriptEngine.CurrentApp.DataFS GetFileFullPathByName:_target];
        _source = [_scriptEngine.CurrentApp.DataFS GetFileFullPathByName:_source];
        if(![[NSFileManager defaultManager] fileExistsAtPath:_target ])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:_target withIntermediateDirectories:YES attributes:nil error:nil];
        }
        doZipArchive *za = [[doZipArchive alloc] init];
        BOOL success=NO;
        if ([za UnzipOpenFile: _source]) {
            success = [za UnzipFileTo: _target overWrite: YES];
            [za UnzipCloseFile];
        }
        [_invokeResult SetResultBoolean:success];
    }
    @catch (NSException *exception) {
        [_invokeResult SetException:exception];
    }
    @finally {
        [_scriptEngine Callback:_callbackFuncName :_invokeResult];
    }
}


- (void)getFileSize:(NSArray*) parms
{
    NSDictionary* _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    doInvokeResult *_invokeResult = [parms objectAtIndex:2];

    NSString *path = [doJsonHelper GetOneText: _dictParas :@"path" :@""];
    
    if (!path || path.length == 0) {
        [[doServiceContainer Instance].LogEngine WriteError:nil : @"路径不能为空"];
        [_invokeResult SetResultText:@"0"];
        return;
    }
    
    if ([path hasSuffix:@"/"]) {
        [[doServiceContainer Instance].LogEngine WriteError:nil : [NSString stringWithFormat:@"%@是一个路径",path]];
        [_invokeResult SetResultText:@"0"];
        return;
    }
    
    NSString *fullPath = [doIOHelper GetLocalFileFullPath:_scriptEngine.CurrentApp :path];
    if (![doIOHelper ExistFile:fullPath]) {
        [[doServiceContainer Instance].LogEngine WriteError:nil : [NSString stringWithFormat:@"%@文件不存在",path]];
        [_invokeResult SetResultText:@"0"];
        return;
    }
    
    NSString *size = [@([self fileSizeAtPath:fullPath]) stringValue];
    [_invokeResult SetResultText:size];
}

- (long long)fileSizeAtPath:(NSString*) path{
    NSFileManager *manager = [NSFileManager defaultManager];
    return [[manager attributesOfItemAtPath:path error:nil] fileSize];
}
@end
