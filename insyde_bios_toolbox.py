#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import ctypes
import json
import time
import subprocess
import threading
import shutil
import glob
import re
from datetime import datetime
from PyQt5.QtCore import QObject, QUrl, pyqtSignal, pyqtSlot, Qt, QMetaObject, QSettings, Q_ARG
from PyQt5.QtGui import QGuiApplication, QIcon
from PyQt5.QtQml import QQmlApplicationEngine
import tempfile
import importlib.util
import struct
from urllib.parse import quote, unquote
import logging

# 设置日志系统
def setup_logging():
    """配置详细的日志记录系统"""
    log_formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    
    # 创建两个文件处理器，一个用于debug日志，一个用于error日志
    debug_handler = logging.FileHandler('debug.log', encoding='utf-8')
    debug_handler.setLevel(logging.DEBUG)
    debug_handler.setFormatter(log_formatter)
    
    error_handler = logging.FileHandler('error.log', encoding='utf-8')
    error_handler.setLevel(logging.ERROR)
    error_handler.setFormatter(log_formatter)
    
    # 创建控制台处理器
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(log_formatter)
    
    # 获取根日志记录器并设置级别
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.DEBUG)
    
    # 清除之前可能存在的处理器
    for handler in root_logger.handlers[:]:
        root_logger.removeHandler(handler)
    
    # 添加处理器到日志记录器
    root_logger.addHandler(debug_handler)
    root_logger.addHandler(error_handler)
    root_logger.addHandler(console_handler)
    
    logging.debug("日志系统初始化完成")

# 常量定义
CONSOLE_EXE = "H2OUVE-W-CONSOLEx64.exe"
GUI_EXE = "H2OUVE-W-GUIx64.exe"
EZE_EXE = "H2OEZE.exe"  # H2OEZE可执行文件
FPT_EXE = "FPTW64.exe"
BACKUP_DIR = "BIOSsetting"
EXTRACT_DIR = "BIOSExtract"
BIOS_BACKUP_DIR = "BIOSBackup"  # 新增BIOS备份专用目录

# 已将所需的BIOSUtilities代码直接集成到该文件中，不再需要外部模块依赖

# 集成BIOSUtilities中必需的代码
# ==== 集成 structs.py ====
class InsydeStructs:
    """从BIOSUtilities集成的结构定义"""
    
    @staticmethod
    def ctypes_struct(buffer, start_offset, class_object, param_list=None):
        """
        从buffer创建ctypes结构体
        """
        if not param_list:
            param_list = []

        structure = class_object(*param_list)
        struct_len = ctypes.sizeof(structure)
        struct_data = buffer[start_offset:start_offset + struct_len]
        least_len = min(len(struct_data), struct_len)
        ctypes.memmove(ctypes.addressof(structure), struct_data, least_len)
        return structure


# ==== 集成 texts.py ====
class InsydeTexts:
    """从BIOSUtilities集成的文本处理函数"""
    
    @staticmethod
    def to_string(in_object, sep_char=''):
        """将对象转换为字符串"""
        if isinstance(in_object, (list, tuple)):
            out_string = sep_char.join(map(str, in_object))
        else:
            out_string = str(in_object)
        return out_string
    
    @staticmethod
    def file_to_bytes(in_object):
        """从文件或缓冲区获取字节"""
        if isinstance(in_object, str):
            with open(in_object, 'rb') as object_fp:
                return object_fp.read()
        return bytes(in_object)


# ==== 集成 system.py ====
class InsydeSystem:
    """从BIOSUtilities集成的系统函数"""
    
    @staticmethod
    def system_platform():
        """获取系统平台信息"""
        import platform
        sys_os = platform.system()
        is_win = sys_os == 'Windows'
        is_lnx = sys_os in ('Linux', 'Darwin')
        return sys_os, is_win, is_lnx
    
    @staticmethod
    def printer(message=None, padding=0, new_line=True, sep_char=' ', strip=False):
        """打印消息"""
        message_string = InsydeTexts.to_string('' if message is None else message, sep_char=sep_char)
        message_output = '\n' if new_line else ''
        
        for message_line_index, message_line_text in enumerate(message_string.split('\n')):
            line_new = '' if message_line_index == 0 else '\n'
            line_text = message_line_text.strip() if strip else message_line_text
            message_output += f'{line_new}{" " * padding}{line_text}'
        
        print(message_output)


# ==== 集成 paths.py ====
class InsydePaths:
    """从BIOSUtilities集成的路径处理函数"""
    
    @staticmethod
    def make_dirs(in_path, parents=True, exist_ok=True, delete=False):
        """创建目录"""
        if delete:
            InsydePaths.delete_dirs(in_path)
        
        os.makedirs(in_path, exist_ok=exist_ok)
    
    @staticmethod
    def delete_dirs(in_path):
        """删除目录"""
        if InsydePaths.is_dir(in_path):
            shutil.rmtree(in_path, onerror=InsydePaths.clear_readonly_callback)
    
    @staticmethod
    def is_dir(in_path):
        """检查路径是否为目录"""
        return os.path.isdir(in_path)
    
    @staticmethod
    def is_file(in_path, allow_broken_links=False):
        """检查路径是否为文件"""
        in_path_abs = os.path.abspath(in_path)
        
        if os.path.lexists(in_path_abs):
            if not InsydePaths.is_dir(in_path_abs):
                if allow_broken_links:
                    return os.path.isfile(in_path_abs) or os.path.islink(in_path_abs)
                return os.path.isfile(in_path_abs)
        
        return False
    
    @staticmethod
    def is_file_read(in_path):
        """检查路径是否为可读文件"""
        return isinstance(in_path, str) and InsydePaths.is_file(in_path) and InsydePaths.is_access(in_path)
    
    @staticmethod
    def is_access(in_path, access_mode=os.R_OK, follow_links=False):
        """检查路径是否可访问"""
        if not follow_links and os.access not in getattr(os, 'supports_follow_symlinks', []):
            follow_links = True
        
        return os.access(in_path, access_mode, follow_symlinks=follow_links)
    
    @staticmethod
    def path_name(in_path, limit=False):
        """获取路径的最后一个组件（文件名）"""
        return os.path.basename(in_path)
    
    @staticmethod
    def extract_folder(in_path, suffix='_extracted'):
        """生成提取文件夹路径"""
        return f"{in_path}{suffix}"
    
    @staticmethod
    def path_files(in_path, follow_links=False, root_only=False):
        """遍历路径获取所有文件"""
        file_paths = []
        
        for root_path, _, file_names in os.walk(in_path, followlinks=follow_links):
            for file_name in file_names:
                file_path = os.path.abspath(os.path.join(root_path, file_name))
                
                if InsydePaths.is_file(file_path):
                    file_paths.append(file_path)
            
            if root_only:
                break
        
        return file_paths
    
    @staticmethod
    def clear_readonly(in_path):
        """清除只读文件属性"""
        import stat
        os.chmod(in_path, stat.S_IWRITE)
    
    @staticmethod
    def clear_readonly_callback(in_func, in_path, _):
        """清除只读文件属性（用于shutil.rmtree错误）"""
        InsydePaths.clear_readonly(in_path)
        in_func(in_path)
    
    @staticmethod
    def delete_file(in_path):
        """删除文件"""
        if InsydePaths.is_file(in_path):
            InsydePaths.clear_readonly(in_path)
            os.remove(in_path)
    
    @staticmethod
    def safe_name(in_name):
        """修复非法/保留的Windows字符"""
        name_repr = repr(in_name).strip("'")
        return re.sub(r'[\\/:"*?<>|]+', '_', name_repr)


# ==== 集成 patterns.py ====
# Insyde相关的正则表达式模式
PAT_INSYDE_IFL = re.compile(br'\$_IFLASH')
PAT_INSYDE_SFX = re.compile(br'\x0D\x0A;!@InstallEnd@!\x0D\x0A(7z\xBC\xAF\x27|\x6E\xF4\x79\x5F\x4E)')


# ==== 集成 templates.py ====
class BIOSUtility:
    """BIOS实用工具基类"""
    
    TITLE = 'BIOS Utility'
    
    def __init__(self, input_object=b'', extract_path='', padding=0):
        self.input_object = input_object
        self.extract_path = extract_path
        self.padding = padding
        self.__input_buffer = b''
    
    @property
    def input_buffer(self):
        """获取输入对象缓冲区"""
        if not self.__input_buffer:
            self.__input_buffer = InsydeTexts.file_to_bytes(self.input_object)
        
        return self.__input_buffer
    
    def check_format(self):
        """检查输入对象是否为特定支持的格式"""
        raise NotImplementedError('Method "check_format" not implemented')
    
    def parse_format(self):
        """将输入对象作为特定支持的格式进行处理"""
        raise NotImplementedError('Method "parse_format" not implemented')


# ==== 集成 compression.py (简化版) ====
def is_szip_supported(in_path, args=None):
    """检查文件是否被7-Zip支持"""
    # 简化版，直接返回True
    return True

def szip_decompress(in_path, out_path, in_name='archive', padding=0, args=None, check=False, silent=False):
    """使用7-Zip解压缩归档"""
    try:
        # 简化版，使用subprocess直接调用7z
        szip_exe = "7z.exe" if os.name == 'nt' else "7z"
        cmd_args = [szip_exe, 'x', '-y', '-o' + out_path, in_path]
        
        if args:
            for arg in args:
                if arg.startswith('-p'):
                    cmd_args.insert(2, arg)
        
        process = subprocess.run(cmd_args, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        if process.returncode in [0, 1] and os.path.isdir(out_path):
            if not silent:
                InsydeSystem.printer(message=f'Successful {in_name} decompression via 7-Zip!', padding=padding)
            return True
        return False
    except:
        return False


# ==== 集成 IflashHeader 结构 ====
class IflashHeader(ctypes.LittleEndianStructure):
    """Insyde iFlash头部"""
    
    _pack_ = 1
    _fields_ = [
        ('Signature',       ctypes.c_char * 8),      # 0x00 $_IFLASH
        ('ImageTag',        ctypes.c_char * 8),      # 0x08
        ('TotalSize',       ctypes.c_uint),          # 0x10 from header end
        ('ImageSize',       ctypes.c_uint)           # 0x14 from header end
        # 0x18
    ]
    
    def _get_padd_len(self):
        return self.TotalSize - self.ImageSize
    
    def get_image_tag(self):
        """获取Insyde iFlash镜像标签"""
        return self.ImageTag.decode('utf-8', 'ignore').strip('_')
    
    def struct_print(self, padding=0):
        """显示结构信息"""
        InsydeSystem.printer(message=['Signature :', self.Signature.decode('utf-8')], padding=padding, new_line=False)
        InsydeSystem.printer(message=['Image Name:', self.get_image_tag()], padding=padding, new_line=False)
        InsydeSystem.printer(message=['Image Size:', f'0x{self.ImageSize:X}'], padding=padding, new_line=False)
        InsydeSystem.printer(message=['Total Size:', f'0x{self.TotalSize:X}'], padding=padding, new_line=False)
        InsydeSystem.printer(message=['Padd Size :', f'0x{self._get_padd_len():X}'], padding=padding, new_line=False)


# ==== 集成 InsydeIfdExtract 类 ====
class InsydeIfdExtract(BIOSUtility):
    """Insyde iFlash/iFdPacker提取器"""
    
    TITLE = 'Insyde iFlash/iFdPacker Extractor'
    
    # Insyde iFdPacker已知的7-Zip SFX密码
    INS_SFX_PWD = 'Y`t~i!L@i#t$U%h^s7A*l(f)E-d=y+S_n?i'
    
    # Insyde iFlash已知的镜像名称
    INS_IFL_IMG = {
        'BIOSCER': ['Certificate', 'bin'],
        'BIOSCR2': ['Certificate 2nd', 'bin'],
        'BIOSIMG': ['BIOS-UEFI', 'bin'],
        'DRV_IMG': ['isflash', 'efi'],
        'EC_IMG': ['Embedded Controller', 'bin'],
        'INI_IMG': ['platform', 'ini'],
        'IOM_IMG': ['IO Manageability', 'bin'],
        'ISH_IMG': ['Integrated Sensor Hub', 'bin'],
        'ME_IMG': ['Management Engine', 'bin'],
        'OEM_ID': ['OEM Identifier', 'bin'],
        'PDT_IMG': ['Platform Descriptor Table', 'bin'],
        'TBT_IMG': ['Integrated Thunderbolt', 'bin']
    }
    
    # 获取常见的ctypes结构体大小
    INS_IFL_LEN = ctypes.sizeof(IflashHeader)
    
    def check_format(self):
        """检查输入是否为Insyde iFlash/iFdPacker更新镜像"""
        if bool(self._insyde_iflash_detect(input_buffer=self.input_buffer)):
            return True
        
        if bool(PAT_INSYDE_SFX.search(self.input_buffer)):
            return True
        
        return False
    
    def parse_format(self):
        """解析并提取Insyde iFlash/iFdPacker更新镜像"""
        iflash_code = self._insyde_iflash_extract(input_buffer=self.input_buffer, extract_path=self.extract_path,
                                               padding=self.padding)
        
        ifdpack_path = os.path.join(self.extract_path, 'Insyde iFdPacker SFX')
        
        ifdpack_code = self._insyde_packer_extract(input_buffer=self.input_buffer, extract_path=ifdpack_path,
                                                padding=self.padding)
        
        return (iflash_code and ifdpack_code) == 0
    
    def _insyde_iflash_detect(self, input_buffer):
        """检测Insyde iFlash更新镜像"""
        iflash_match_all = []
        iflash_match_nan = [0x0, 0xFFFFFFFF]
        
        for iflash_match in PAT_INSYDE_IFL.finditer(input_buffer):
            ifl_bgn = iflash_match.start()
            
            if len(input_buffer[ifl_bgn:]) <= self.INS_IFL_LEN:
                continue
            
            ifl_hdr = InsydeStructs.ctypes_struct(buffer=input_buffer, start_offset=ifl_bgn, class_object=IflashHeader)
            
            if ifl_hdr.TotalSize in iflash_match_nan \
                    or ifl_hdr.ImageSize in iflash_match_nan \
                    or ifl_hdr.TotalSize < ifl_hdr.ImageSize \
                    or ifl_bgn + self.INS_IFL_LEN + ifl_hdr.TotalSize > len(input_buffer):
                continue
            
            iflash_match_all.append([ifl_bgn, ifl_hdr])
        
        return iflash_match_all
    
    def _insyde_iflash_extract(self, input_buffer, extract_path, padding=0):
        """提取Insyde iFlash更新镜像"""
        insyde_iflash_all = self._insyde_iflash_detect(input_buffer=input_buffer)
        
        if not insyde_iflash_all:
            return 127
        
        InsydeSystem.printer(message='Detected Insyde iFlash Update image!', padding=padding)
        
        InsydePaths.make_dirs(in_path=extract_path)
        
        exit_codes = []
        
        for insyde_iflash in insyde_iflash_all:
            exit_code = 0
            
            ifl_bgn, ifl_hdr = insyde_iflash
            
            img_bgn = ifl_bgn + self.INS_IFL_LEN
            img_end = img_bgn + ifl_hdr.ImageSize
            img_bin = input_buffer[img_bgn:img_end]
            
            if len(img_bin) != ifl_hdr.ImageSize:
                exit_code = 1
            
            img_val = [ifl_hdr.get_image_tag(), 'bin']
            img_tag, img_ext = self.INS_IFL_IMG.get(img_val[0], img_val)
            
            img_name = f'{img_tag} [0x{img_bgn:08X}-0x{img_end:08X}]'
            
            InsydeSystem.printer(message=f'{img_name}\n', padding=padding + 4)
            
            ifl_hdr.struct_print(padding=padding + 8)
            
            if img_val == [img_tag, img_ext]:
                InsydeSystem.printer(message=f'Note: Detected new Insyde iFlash tag {img_tag}!', padding=padding + 12)
            
            out_name = f'{img_name}.{img_ext}'
            
            out_path = os.path.join(extract_path, InsydePaths.safe_name(in_name=out_name))
            
            with open(out_path, 'wb') as out_image:
                out_image.write(img_bin)
            
            InsydeSystem.printer(message=f'Successful Insyde iFlash > {img_tag} extraction!', padding=padding + 12)
            
            exit_codes.append(exit_code)
        
        return sum(exit_codes)
    
    def _insyde_packer_extract(self, input_buffer, extract_path, padding=0):
        """提取Insyde iFdPacker 7-Zip SFX 7z更新镜像"""
        match_sfx = PAT_INSYDE_SFX.search(input_buffer)
        
        if not match_sfx:
            return 127
        
        InsydeSystem.printer(message='Detected Insyde iFdPacker Update image!', padding=padding)
        
        InsydePaths.make_dirs(in_path=extract_path, delete=True)
        
        sfx_buffer = bytearray(input_buffer[match_sfx.end() - 0x5:])
        
        if sfx_buffer[:0x5] == b'\x6E\xF4\x79\x5F\x4E':
            InsydeSystem.printer(message='Detected Insyde iFdPacker > 7-Zip SFX > Obfuscation!', padding=padding + 4)
            
            for index, byte in enumerate(sfx_buffer):
                sfx_buffer[index] = byte // 2 + (128 if byte % 2 else 0)
            
            InsydeSystem.printer(message='Removed Insyde iFdPacker > 7-Zip SFX > Obfuscation!', padding=padding + 8)
        
        InsydeSystem.printer(message='Extracting Insyde iFdPacker > 7-Zip SFX archive...', padding=padding + 4)
        
        if bytes(self.INS_SFX_PWD, 'utf-16le') in input_buffer[:match_sfx.start()]:
            InsydeSystem.printer(message='Detected Insyde iFdPacker > 7-Zip SFX > Password!', padding=padding + 8)
            InsydeSystem.printer(message=self.INS_SFX_PWD, padding=padding + 12)
        
        sfx_path = os.path.join(extract_path, 'Insyde_iFdPacker_SFX.7z')
        
        with open(sfx_path, 'wb') as sfx_file_object:
            sfx_file_object.write(sfx_buffer)
        
        if is_szip_supported(in_path=sfx_path, args=[f'-p{self.INS_SFX_PWD}']):
            if szip_decompress(in_path=sfx_path, out_path=extract_path, in_name='Insyde iFdPacker > 7-Zip SFX',
                               padding=padding + 8, args=[f'-p{self.INS_SFX_PWD}'], check=True):
                InsydePaths.delete_file(in_path=sfx_path)
            else:
                return 125
        else:
            return 126
        
        exit_codes = []
        
        for sfx_file in InsydePaths.path_files(in_path=extract_path):
            if InsydePaths.is_file_read(in_path=sfx_file):
                insyde_ifd_extract = InsydeIfdExtract(
                    input_object=sfx_file, extract_path=InsydePaths.extract_folder(sfx_file), padding=padding + 16)
                
                if insyde_ifd_extract.check_format():
                    InsydeSystem.printer(message=InsydePaths.path_name(in_path=sfx_file), padding=padding + 12)
                    
                    ifd_status = insyde_ifd_extract.parse_format()
                    
                    exit_codes.append(0 if ifd_status else 1)
        
        return sum(exit_codes)

# BIOS提取器类 - 修改以使用集成的InsydeIfdExtract
class BiosExtractor:
    """处理BIOS提取和解析的类"""
    
    def __init__(self):
        # 确保提取目录存在
        os.makedirs(EXTRACT_DIR, exist_ok=True)
    
    def extract_system_bios(self):
        """从系统提取BIOS固件"""
        try:
            # 检查管理员权限
            if not is_admin():
                return False, "提取BIOS需要管理员权限，请以管理员身份运行程序", []
            
            # 确保BIOS备份目录存在
            logging.debug(f"确保BIOS备份目录存在: {BIOS_BACKUP_DIR}")
            os.makedirs(BIOS_BACKUP_DIR, exist_ok=True)
            
            # 使用时间戳生成文件名
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_file = os.path.join(BIOS_BACKUP_DIR, f"BIOS_Backup_{timestamp}.bin")
            logging.debug(f"BIOS备份文件路径: {output_file}")
            
            # 获取FPT工具路径
            fpt_exe_path = get_exe_path(FPT_EXE)
            logging.debug(f"FPT工具路径: {fpt_exe_path}")
            
            if not os.path.exists(fpt_exe_path):
                error_msg = f"FPT工具不存在: {fpt_exe_path}"
                logging.error(error_msg)
                return False, error_msg, []
            
            # 使用FPT工具提取系统BIOS
            cmd_args = [fpt_exe_path, '-d', output_file, '-bios']
            logging.debug(f"执行FPT命令: {' '.join(cmd_args)}")
            
            # 创建无窗口进程
            startupinfo = subprocess.STARTUPINFO()
            startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            startupinfo.wShowWindow = 0  # SW_HIDE
            
            try:
                process = subprocess.run(
                    cmd_args, 
                    capture_output=True, 
                    text=True, 
                    startupinfo=startupinfo
                )
                logging.debug(f"FPT命令执行完成，返回代码: {process.returncode}")
                logging.debug(f"标准输出: {process.stdout}")
                if process.stderr:
                    logging.debug(f"错误输出: {process.stderr}")
            except Exception as e:
                error_msg = f"执行FPT命令异常: {str(e)}"
                logging.exception(error_msg)
                return False, error_msg, []
            
            if process.returncode == 0 and os.path.exists(output_file):
                # 检查文件大小
                file_size = os.path.getsize(output_file)
                logging.debug(f"BIOS备份成功，文件大小: {file_size} 字节")
                
                # 不执行解析，直接返回成功信息和文件列表
                files = [{
                    "name": os.path.basename(output_file),
                    "path": output_file,
                    "size": self._format_file_size(os.path.getsize(output_file)),
                    "time": timestamp
                }]
                
                success_msg = f"BIOS备份成功保存到{BIOS_BACKUP_DIR}目录"
                logging.info(success_msg)
                return True, success_msg, files
            else:
                error_msg = process.stderr if process.stderr else process.stdout if process.stdout else "未知错误"
                
                # 检查是否是权限相关错误
                if "administrator" in error_msg or "privileged" in error_msg or "permission" in error_msg:
                    error_msg = "提取BIOS需要管理员权限，请以管理员身份运行程序"
                    logging.error(error_msg)
                    return False, error_msg, []
                elif "Failed to communicate with CSME" in error_msg:
                    error_msg = "无法与芯片组管理引擎通信，请确保您以管理员身份运行程序并且硬件支持该操作"
                    logging.error(error_msg)
                    return False, error_msg, []
                else:
                    error_msg = f"系统BIOS提取失败: {error_msg}"
                    logging.error(error_msg)
                    return False, error_msg, []
                
        except Exception as e:
            error_msg = f"系统BIOS提取出错: {str(e)}"
            logging.exception(error_msg)
            return False, error_msg, []
    
    def parse_bios_file(self, file_path):
        """解析BIOS固件文件"""
        try:
            if not os.path.exists(file_path):
                return False, f"文件不存在: {file_path}", []
            
            extract_path = os.path.join(EXTRACT_DIR, os.path.basename(file_path) + "_extracted")
            
            # 直接使用集成的InsydeIfdExtract类
            with open(file_path, 'rb') as f:
                bios_data = f.read()
            
            # 创建提取器实例
            extractor = InsydeIfdExtract(
                input_object=file_path,
                extract_path=extract_path,
                padding=0
            )
            
            # 检查是否是支持的格式
            if extractor.check_format():
                # 解析和提取
                parse_result = extractor.parse_format()
                
                if parse_result:
                    # 成功解析，获取提取的文件列表
                    extracted_files = self._get_extracted_files(extract_path)
                    return True, "BIOS固件解析成功", extracted_files
                else:
                    return False, "BIOS固件解析失败，可能是不支持的格式", []
            else:
                # 如果不是Insyde IFD格式，尝试基本的解析
                return self._basic_bios_parse(file_path, extract_path)
                
        except Exception as e:
            return False, f"BIOS固件解析出错: {str(e)}", []
    
    def _basic_bios_parse(self, file_path, extract_path):
        """基本的BIOS解析，在无法使用BIOSUtilities时使用"""
        try:
            # 确保提取目录存在
            os.makedirs(extract_path, exist_ok=True)
            
            # 读取文件
            with open(file_path, 'rb') as f:
                bios_data = f.read()
            
            # 提取一些基本信息
            bios_info_file = os.path.join(extract_path, "bios_info.txt")
            
            with open(bios_info_file, 'w') as f:
                f.write(f"BIOS文件: {os.path.basename(file_path)}\n")
                f.write(f"文件大小: {len(bios_data):,} 字节\n")
                f.write(f"解析时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
                
                # 尝试提取一些字符串信息
                printable_chars = re.compile(b'[ -~]{8,}')  # 至少8个可打印ASCII字符
                strings = printable_chars.findall(bios_data)
                
                f.write("发现的字符串:\n")
                for i, string in enumerate(strings[:100]):  # 限制为前100个字符串
                    try:
                        decoded = string.decode('utf-8', errors='replace')
                        f.write(f"{i+1}. {decoded}\n")
                    except:
                        continue
            
            # 创建原始BIOS副本
            bios_copy = os.path.join(extract_path, os.path.basename(file_path))
            shutil.copy2(file_path, bios_copy)
            
            # 返回提取的文件列表
            extracted_files = self._get_extracted_files(extract_path)
            return True, "BIOS固件已保存并进行了基本解析", extracted_files
            
        except Exception as e:
            return False, f"基本BIOS解析出错: {str(e)}", []
    
    def _get_extracted_files(self, extract_path):
        """获取提取目录中的文件列表"""
        extracted_files = []
        
        for root, dirs, files in os.walk(extract_path):
            for file in files:
                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, extract_path)
                size = os.path.getsize(file_path)
                
                # 格式化文件大小
                if size < 1024:
                    size_str = f"{size} B"
                elif size < 1024 * 1024:
                    size_str = f"{size/1024:.1f} KB"
                else:
                    size_str = f"{size/(1024*1024):.1f} MB"
                
                extracted_files.append({
                    "name": rel_path,
                    "path": file_path,
                    "size": size_str
                })
        
        return extracted_files

    def _format_file_size(self, size):
        """格式化文件大小"""
        if size < 1024:
            return f"{size} B"
        elif size < 1024 * 1024:
            return f"{size/1024:.1f} KB"
        else:
            return f"{size/(1024*1024):.1f} MB"

# 以下是原代码，删除了对BIOSUtilities的外部依赖
def is_admin():
    """检查是否具有管理员权限"""
    try:
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except:
        return False

def run_as_admin():
    """以管理员权限重新启动程序"""
    try:
        # 获取当前脚本的完整路径
        script = os.path.abspath(sys.argv[0])
        params = ' '.join(sys.argv[1:])
        
        # 记录日志
        logging.info(f"尝试以管理员权限重启程序")
        logging.debug(f"脚本路径: {script}")
        logging.debug(f"参数: {params}")
        
        # 使用ShellExecuteW以管理员权限启动程序
        logging.debug("调用ShellExecuteW以管理员权限启动程序")
        ret = ctypes.windll.shell32.ShellExecuteW(
            None, 
            "runas", 
            sys.executable, 
            f'"{script}" {params}', 
            None, 
            1  # SW_SHOWNORMAL
        )
        
        # 检查返回值
        if ret <= 32:  # 如果返回值小于等于32，表示发生错误
            error_msg = f"ShellExecuteW返回错误代码: {ret}"
            logging.error(error_msg)
        else:
            logging.info(f"ShellExecuteW调用成功，返回值: {ret}")
    except Exception as e:
        error_msg = f"以管理员权限重启时出错: {str(e)}"
        logging.exception(error_msg)

def path_to_url(path):
    """将本地路径转换为URL，处理中文路径问题"""
    path = os.path.abspath(path)
    if sys.platform == 'win32':
        path = path.replace('\\', '/')
        if not path.startswith('/'):
            path = '/' + path
    # 确保中文路径正确编码
    path = quote(path)
    return QUrl.fromLocalFile(path)

class BiosToolBackend(QObject):
    """与QML界面交互的后端类"""
    # 定义信号
    flashResultSignal = pyqtSignal(bool, str, arguments=['success', 'message'])
    backupResultSignal = pyqtSignal(bool, str, arguments=['success', 'message'])
    writeResultSignal = pyqtSignal(bool, str, arguments=['success', 'message'])
    extractResultSignal = pyqtSignal(bool, str, list, arguments=['success', 'message', 'files'])
    
    def __init__(self):
        super().__init__()
        # 确保必要目录存在
        os.makedirs(BACKUP_DIR, exist_ok=True)
        os.makedirs(EXTRACT_DIR, exist_ok=True)
        os.makedirs(BIOS_BACKUP_DIR, exist_ok=True)
        
        # 初始化BIOS提取器
        self.bios_extractor = BiosExtractor()
        
    @pyqtSlot(str)
    def handle_menu_item_clicked(self, item_id):
        """处理菜单项点击事件"""
        print(f"菜单项 {item_id} 被点击")
        
        # 基于ID执行相应操作
        if item_id == "extract_firmware":
            print("启动BIOS固件提取功能")
        elif item_id == "backup_firmware":
            print("启动BIOS固件备份功能")
        elif item_id == "flash_firmware":
            print("启动BIOS固件刷写功能")
        elif item_id == "h2ouve_editor":
            print("启动H2OUVE编辑器")
            self.launch_h2ouve()
        elif item_id == "h2oeze_editor":
            print("启动H2OEZE编辑器")
            self.launch_h2oeze()
    
    def launch_h2ouve(self):
        """启动H2OUVE编辑器"""
        try:
            # 使用get_exe_path获取GUI_EXE路径
            gui_exe_path = get_exe_path(GUI_EXE)
            logging.debug(f"尝试启动H2OUVE编辑器: {gui_exe_path}")
            
            if not os.path.exists(gui_exe_path):
                logging.error(f"H2OUVE GUI程序不存在: {gui_exe_path}")
                return
                
            # 启动编辑器
            subprocess.Popen([gui_exe_path], shell=True)
            logging.info("成功启动H2OUVE编辑器")
        except Exception as e:
            logging.exception(f"启动H2OUVE编辑器失败: {e}")
    
    def launch_h2oeze(self):
        """启动H2OEZE编辑器"""
        try:
            # 使用get_exe_path获取EZE_EXE路径
            eze_exe_path = get_exe_path(EZE_EXE)
            logging.debug(f"尝试启动H2OEZE编辑器: {eze_exe_path}")
            
            if not os.path.exists(eze_exe_path):
                logging.error(f"H2OEZE程序不存在: {eze_exe_path}")
                return
                
            # 启动编辑器
            subprocess.Popen([eze_exe_path], shell=True)
            logging.info("成功启动H2OEZE编辑器")
        except Exception as e:
            logging.exception(f"启动H2OEZE编辑器失败: {e}")
    
    @pyqtSlot()
    def extractSystemBios(self):
        """提取系统BIOS固件"""
        # 创建线程来执行提取操作，避免UI卡顿
        extract_thread = threading.Thread(
            target=self._do_extract_system_bios
        )
        extract_thread.daemon = True
        extract_thread.start()
    
    def _do_extract_system_bios(self):
        """执行系统BIOS提取的实际操作"""
        success, message, files = self.bios_extractor.extract_system_bios()
        self._emit_extract_result(success, message, files)
    
    @pyqtSlot(str)
    def extractBiosFile(self, file_path):
        """解析BIOS固件文件"""
        # 创建线程来执行解析操作，避免UI卡顿
        parse_thread = threading.Thread(
            target=self._do_extract_bios_file,
            args=(file_path,)
        )
        parse_thread.daemon = True
        parse_thread.start()
    
    def _do_extract_bios_file(self, file_path):
        """执行BIOS固件解析的实际操作"""
        success, message, files = self.bios_extractor.parse_bios_file(file_path)
        self._emit_extract_result(success, message, files)
    
    def _emit_extract_result(self, success, message, files):
        """发射提取结果信号"""
        # 使用QMetaObject.invokeMethod确保信号在主线程发射
        QMetaObject.invokeMethod(
            self, 
            "extractResultSignal", 
            Qt.QueuedConnection,
            Q_ARG(bool, success),
            Q_ARG(str, message),
            Q_ARG(list, files)
        )
    
    @pyqtSlot(str)
    def openFileLocation(self, file_path):
        """打开文件所在的位置"""
        try:
            # 解码URL编码的路径
            file_path = unquote(file_path)
            
            if os.path.exists(file_path):
                # 使用系统默认方式打开文件所在文件夹
                if sys.platform == 'win32':
                    subprocess.Popen(f'explorer /select,"{file_path}"', shell=True)
                else:
                    subprocess.Popen(['xdg-open', os.path.dirname(file_path)])
            else:
                print(f"路径不存在: {file_path}")
        except Exception as e:
            print(f"打开文件位置失败: {e}")
    
    @pyqtSlot(str)
    def flashFirmware(self, params_str):
        """刷写BIOS固件"""
        # 解析参数
        params = json.loads(params_str)
        file_path = params.get('filePath', '')
        reboot_after = params.get('rebootAfter', True)
        
        print(f"准备刷写BIOS固件: {file_path}")
        print(f"完成后重启: {reboot_after}")
        
        # 创建线程来执行刷写操作，避免UI卡顿
        flash_thread = threading.Thread(
            target=self._do_flash_firmware, 
            args=(file_path, reboot_after)
        )
        flash_thread.daemon = True
        flash_thread.start()
    
    def _do_flash_firmware(self, file_path, reboot_after):
        """执行固件刷写的实际操作"""
        try:
            # 检查管理员权限
            if not is_admin():
                self._emit_flash_result(False, "刷写BIOS需要管理员权限，请以管理员身份运行程序")
                return
            
            # 解码URL编码的路径
            file_path = unquote(file_path)
            logging.debug(f"BIOS固件文件路径: {file_path}")
                
            if not os.path.exists(file_path):
                error_msg = f"文件不存在: {file_path}"
                logging.error(error_msg)
                self._emit_flash_result(False, error_msg)
                return
            
            # 获取文件大小信息
            file_size = os.path.getsize(file_path)
            logging.debug(f"BIOS固件文件大小: {file_size} 字节")
            
            # 获取FPT工具路径
            fpt_exe_path = get_exe_path(FPT_EXE)
            logging.debug(f"FPT工具路径: {fpt_exe_path}")
            
            if not os.path.exists(fpt_exe_path):
                error_msg = f"FPT工具不存在: {fpt_exe_path}"
                logging.error(error_msg)
                self._emit_flash_result(False, error_msg)
                return
                
            # 构建命令，始终使用-bios参数
            cmd_args = [fpt_exe_path, '-f', file_path, '-bios']
            logging.debug(f"执行FPT命令: {' '.join(cmd_args)}")
            
            # 创建无窗口进程
            startupinfo = subprocess.STARTUPINFO()
            startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            startupinfo.wShowWindow = 0  # SW_HIDE
            
            # 执行刷写命令
            logging.debug("开始执行刷写命令")
            try:
                process = subprocess.run(
                    cmd_args, 
                    capture_output=True, 
                    text=True, 
                    startupinfo=startupinfo
                )
                logging.debug(f"刷写命令执行完成，返回代码: {process.returncode}")
                logging.debug(f"标准输出: {process.stdout}")
                if process.stderr:
                    logging.debug(f"错误输出: {process.stderr}")
            except Exception as e:
                error_msg = f"执行刷写命令异常: {str(e)}"
                logging.exception(error_msg)
                self._emit_flash_result(False, error_msg)
                return
            
            if process.returncode == 0:
                message = "BIOS固件刷写成功"
                if reboot_after:
                    message += "，系统将在10秒后重启..."
                
                logging.info(message)
                self._emit_flash_result(True, message)
                
                # 如果需要重启，等待10秒后重启
                if reboot_after:
                    logging.info("准备在10秒后重启系统...")
                    time.sleep(10)
                    # 创建重启命令
                    logging.info("执行系统重启命令")
                    subprocess.Popen(['shutdown', '-r', '-t', '0'], shell=True)
            else:
                error_msg = process.stderr if process.stderr else process.stdout if process.stdout else "未知错误"
                
                # 检查是否是权限相关错误
                if "administrator" in error_msg or "privileged" in error_msg or "permission" in error_msg:
                    error_msg = "刷写BIOS需要管理员权限，请以管理员身份运行程序"
                    logging.error(error_msg)
                    self._emit_flash_result(False, error_msg)
                elif "Failed to communicate with CSME" in error_msg:
                    error_msg = "无法与芯片组管理引擎通信，请确保您以管理员身份运行程序并且硬件支持该操作"
                    logging.error(error_msg)
                    self._emit_flash_result(False, error_msg)
                else:
                    error_msg = f"固件刷写失败: {error_msg}"
                    logging.error(error_msg)
                    self._emit_flash_result(False, error_msg)
                
        except Exception as e:
            error_msg = f"操作出错: {str(e)}"
            logging.exception(error_msg)
            self._emit_flash_result(False, error_msg)
    
    def _emit_flash_result(self, success, message):
        """发射刷写结果信号"""
        # 使用QMetaObject.invokeMethod确保信号在主线程发射
        QMetaObject.invokeMethod(
            self, 
            "flashResultSignal", 
            Qt.QueuedConnection,
            Q_ARG(bool, success),
            Q_ARG(str, message)
        )
        
    @pyqtSlot(str)
    def backupBiosConfig(self, params_str):
        """备份BIOS配置"""
        # 解析参数
        params = json.loads(params_str)
        file_name = params.get('fileName', '')
        
        print(f"准备备份BIOS配置到文件: {file_name}")
        
        # 创建线程来执行备份操作，避免UI卡顿
        backup_thread = threading.Thread(
            target=self._do_backup_config, 
            args=(file_name,)
        )
        backup_thread.daemon = True
        backup_thread.start()
    
    def _do_backup_config(self, file_name):
        """执行BIOS配置备份的实际操作"""
        try:
            # 记录备份开始
            logging.debug(f"开始备份BIOS配置到文件: {file_name}")
            
            # 确保备份目录存在
            logging.debug(f"确保备份目录存在: {BACKUP_DIR}")
            if not os.path.exists(BACKUP_DIR):
                logging.debug(f"创建备份目录: {BACKUP_DIR}")
            os.makedirs(BACKUP_DIR, exist_ok=True)
            
            # 构建完整的文件路径
            file_path = os.path.join(BACKUP_DIR, file_name)
            logging.debug(f"备份文件完整路径: {file_path}")
            
            # 检查H2OUVE程序是否存在
            console_exe_path = get_exe_path(CONSOLE_EXE)
            logging.debug(f"检查H2OUVE控制台程序: {console_exe_path}")
            if not os.path.exists(console_exe_path):
                error_msg = f"H2OUVE控制台程序不存在: {console_exe_path}"
                logging.error(error_msg)
                self._emit_backup_result(False, error_msg)
                return
            
            # 构建命令
            cmd_args = [console_exe_path, '-gv', file_path]
            logging.debug(f"执行备份命令: {' '.join(cmd_args)}")
            
            # 创建无窗口进程
            startupinfo = subprocess.STARTUPINFO()
            startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            startupinfo.wShowWindow = 0  # SW_HIDE
            
            # 执行备份命令
            logging.debug("开始执行备份命令")
            try:
                process = subprocess.run(
                    cmd_args, 
                    capture_output=True, 
                    text=True, 
                    startupinfo=startupinfo
                )
                logging.debug(f"备份命令执行完成，返回代码: {process.returncode}")
                logging.debug(f"标准输出: {process.stdout}")
                if process.stderr:
                    logging.debug(f"错误输出: {process.stderr}")
            except Exception as e:
                error_msg = f"执行备份命令异常: {str(e)}"
                logging.error(error_msg)
                self._emit_backup_result(False, error_msg)
                return
            
            # 检查备份结果
            if process.returncode == 0 and os.path.exists(file_path):
                # 检查文件大小
                file_size = os.path.getsize(file_path)
                logging.debug(f"备份成功，文件大小: {file_size} 字节")
                
                # 检查文件内容
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
                        content_preview = f.read(100)  # 只读取前100个字符用于日志
                    logging.debug(f"文件内容预览: {content_preview}...")
                except Exception as e:
                    logging.warning(f"读取备份文件内容时出错: {str(e)}")
                
                success_msg = f"BIOS配置备份成功: {file_name}"
                logging.info(success_msg)
                self._emit_backup_result(True, success_msg)
            else:
                error_msg = process.stderr if process.stderr else "未知错误"
                logging.error(f"BIOS配置备份失败: {error_msg}")
                self._emit_backup_result(False, f"BIOS配置备份失败: {error_msg}")
                
        except Exception as e:
            error_msg = f"备份操作出错: {str(e)}"
            logging.exception(error_msg)  # 记录完整堆栈跟踪
            self._emit_backup_result(False, error_msg)
    
    def _emit_backup_result(self, success, message):
        """发射备份结果信号"""
        # 使用QMetaObject.invokeMethod确保信号在主线程发射
        QMetaObject.invokeMethod(
            self, 
            "backupResultSignal", 
            Qt.QueuedConnection,
            Q_ARG(bool, success),
            Q_ARG(str, message)
        )
        
    @pyqtSlot(str)
    def writeBiosConfig(self, params_str):
        """写入BIOS配置"""
        # 解析参数
        params = json.loads(params_str)
        file_name = params.get('fileName', '')
        is_import = params.get('isImport', False)
        
        print(f"准备写入BIOS配置文件: {file_name}")
        print(f"是否为导入文件: {is_import}")
        
        # 创建线程来执行写入操作，避免UI卡顿
        write_thread = threading.Thread(
            target=self._do_write_config, 
            args=(file_name, is_import)
        )
        write_thread.daemon = True
        write_thread.start()
    
    def _do_write_config(self, file_name, is_import):
        """执行BIOS配置写入的实际操作"""
        try:
            # 记录写入开始
            logging.debug(f"开始写入BIOS配置文件: {file_name}")
            logging.debug(f"是否为导入文件: {is_import}")
            
            # 确定文件路径
            if is_import:
                file_path = file_name  # 导入模式，文件名就是完整路径
                logging.debug(f"使用导入模式，文件路径: {file_path}")
            else:
                file_path = os.path.join(BACKUP_DIR, file_name)  # 非导入模式，从备份目录获取
                logging.debug(f"从备份目录获取文件，路径: {file_path}")
            
            # 检查文件是否存在
            logging.debug(f"检查文件是否存在: {file_path}")
            if not os.path.exists(file_path):
                error_msg = f"文件不存在: {file_path}"
                logging.error(error_msg)
                self._emit_write_result(False, error_msg)
                return
            
            # 检查文件内容
            try:
                with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
                    content_preview = f.read(100)  # 只读取前100个字符用于日志
                logging.debug(f"文件内容预览: {content_preview}...")
                
                # 检查文件大小
                file_size = os.path.getsize(file_path)
                logging.debug(f"文件大小: {file_size} 字节")
            except Exception as e:
                logging.warning(f"读取配置文件内容时出错: {str(e)}")
                
            # 检查H2OUVE程序是否存在
            console_exe_path = get_exe_path(CONSOLE_EXE)
            logging.debug(f"检查H2OUVE控制台程序: {console_exe_path}")
            if not os.path.exists(console_exe_path):
                error_msg = f"H2OUVE控制台程序不存在: {console_exe_path}"
                logging.error(error_msg)
                self._emit_write_result(False, error_msg)
                return
                
            # 构建命令
            cmd_args = [console_exe_path, '-sv', file_path]
            logging.debug(f"执行写入命令: {' '.join(cmd_args)}")
            
            # 创建无窗口进程
            startupinfo = subprocess.STARTUPINFO()
            startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            startupinfo.wShowWindow = 0  # SW_HIDE
            
            # 执行写入命令
            logging.debug("开始执行写入命令")
            try:
                process = subprocess.run(
                    cmd_args, 
                    capture_output=True, 
                    text=True, 
                    startupinfo=startupinfo
                )
                logging.debug(f"写入命令执行完成，返回代码: {process.returncode}")
                logging.debug(f"标准输出: {process.stdout}")
                if process.stderr:
                    logging.debug(f"错误输出: {process.stderr}")
            except Exception as e:
                error_msg = f"执行写入命令异常: {str(e)}"
                logging.error(error_msg)
                self._emit_write_result(False, error_msg)
                return
            
            # 检查写入结果
            if process.returncode == 0:
                success_msg = f"BIOS配置写入成功，可能需要重启系统以应用更改"
                logging.info(success_msg)
                self._emit_write_result(True, success_msg)
            else:
                error_msg = process.stderr if process.stderr else "未知错误"
                logging.error(f"BIOS配置写入失败: {error_msg}")
                self._emit_write_result(False, f"BIOS配置写入失败: {error_msg}")
                
        except Exception as e:
            error_msg = f"写入操作出错: {str(e)}"
            logging.exception(error_msg)  # 记录完整堆栈跟踪
            self._emit_write_result(False, error_msg)
    
    def _emit_write_result(self, success, message):
        """发射写入结果信号"""
        # 使用QMetaObject.invokeMethod确保信号在主线程发射
        QMetaObject.invokeMethod(
            self, 
            "writeResultSignal", 
            Qt.QueuedConnection,
            Q_ARG(bool, success),
            Q_ARG(str, message)
        )
        
    @pyqtSlot(result=list)
    def getBackupFiles(self):
        """获取备份配置文件列表"""
        try:
            # 确保备份目录存在
            os.makedirs(BACKUP_DIR, exist_ok=True)
            
            backup_files = []
            
            # 遍历备份目录中的文件
            for file in os.listdir(BACKUP_DIR):
                if os.path.isfile(os.path.join(BACKUP_DIR, file)):
                    # 获取文件大小和修改时间
                    file_path = os.path.join(BACKUP_DIR, file)
                    size = os.path.getsize(file_path)
                    mtime = os.path.getmtime(file_path)
                    
                    # 格式化文件大小和修改时间
                    if size < 1024:
                        size_str = f"{size} B"
                    elif size < 1024 * 1024:
                        size_str = f"{size/1024:.1f} KB"
                    else:
                        size_str = f"{size/(1024*1024):.1f} MB"
                    
                    date_str = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M:%S")
                    
                    backup_files.append({
                        "name": file,
                        "path": file_path,
                        "size": size_str,
                        "date": date_str
                    })
            
            # 按修改时间排序，最新的在前
            backup_files.sort(key=lambda x: x["date"], reverse=True)
            
            return backup_files
            
        except Exception as e:
            print(f"获取备份文件列表出错: {e}")
            return []
        
    @pyqtSlot(result=list)
    def getExtractedBiosFiles(self):
        """获取提取的BIOS固件文件列表"""
        try:
            # 确保提取目录存在
            os.makedirs(EXTRACT_DIR, exist_ok=True)
            os.makedirs(BIOS_BACKUP_DIR, exist_ok=True)
            
            # 获取目录中的.bin和.fd文件
            files = []
            
            # 搜索EXTRACT_DIR目录
            for root, _, file_names in os.walk(EXTRACT_DIR):
                for file_name in file_names:
                    if file_name.endswith('.bin') or file_name.endswith('.fd') or file_name.endswith('.rom'):
                        file_path = os.path.join(root, file_name)
                        
                        # 获取文件大小
                        size = os.path.getsize(file_path)
                        
                        # 格式化文件大小
                        if size < 1024:
                            size_str = f"{size} B"
                        elif size < 1024 * 1024:
                            size_str = f"{size/1024:.1f} KB"
                        else:
                            size_str = f"{size/(1024*1024):.1f} MB"
                        
                        # 获取文件修改时间
                        mod_time = os.path.getmtime(file_path)
                        mod_time_str = datetime.fromtimestamp(mod_time).strftime("%Y-%m-%d %H:%M:%S")
                        
                        files.append({
                            "name": file_name,
                            "path": file_path,
                            "size": size_str,
                            "time": mod_time_str
                        })
                        
            # 搜索BIOS_BACKUP_DIR目录
            for file_name in os.listdir(BIOS_BACKUP_DIR):
                file_path = os.path.join(BIOS_BACKUP_DIR, file_name)
                if os.path.isfile(file_path) and (file_name.endswith('.bin') or file_name.endswith('.fd') or file_name.endswith('.rom')):
                    # 获取文件大小
                    size = os.path.getsize(file_path)
                    
                    # 格式化文件大小
                    if size < 1024:
                        size_str = f"{size} B"
                    elif size < 1024 * 1024:
                        size_str = f"{size/1024:.1f} KB"
                    else:
                        size_str = f"{size/(1024*1024):.1f} MB"
                    
                    # 获取文件修改时间
                    mod_time = os.path.getmtime(file_path)
                    mod_time_str = datetime.fromtimestamp(mod_time).strftime("%Y-%m-%d %H:%M:%S")
                    
                    files.append({
                        "name": file_name,
                        "path": file_path,
                        "size": size_str,
                        "time": mod_time_str
                    })
            
            # 按修改时间排序，最新的文件在前面
            files.sort(key=lambda x: os.path.getmtime(x["path"]), reverse=True)
            
            return files
            
        except Exception as e:
            print(f"获取提取的BIOS文件列表失败: {e}")
            return []
    
    @pyqtSlot(str, result=str)
    def readBackupFile(self, file_name):
        """读取备份文件内容"""
        try:
            file_path = os.path.join(BACKUP_DIR, file_name)
            
            if not os.path.exists(file_path):
                return f"文件不存在: {file_path}"
            
            # 读取文件内容
            with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
                content = f.read()
            
            return content
            
        except Exception as e:
            return f"读取文件出错: {str(e)}"
    
    @pyqtSlot(str, result=bool)
    def deleteBackupFile(self, file_name):
        """删除备份文件"""
        try:
            file_path = os.path.join(BACKUP_DIR, file_name)
            
            if not os.path.exists(file_path):
                return False
            
            # 删除文件
            os.remove(file_path)
            
            return True
            
        except Exception as e:
            print(f"删除文件出错: {e}")
            return False
    
    @pyqtSlot(str, str, result=bool)
    def renameBackupFile(self, old_name, new_name):
        """重命名备份文件"""
        try:
            old_path = os.path.join(BACKUP_DIR, old_name)
            new_path = os.path.join(BACKUP_DIR, new_name)
            
            if not os.path.exists(old_path):
                return False
            
            if os.path.exists(new_path):
                return False
            
            # 重命名文件
            os.rename(old_path, new_path)
            
            return True
            
        except Exception as e:
            print(f"重命名文件出错: {e}")
            return False

    @pyqtSlot(str, str, result=bool)
    def renameBiosFile(self, old_path, new_path):
        """重命名BIOS文件"""
        try:
            # 解码URL编码的路径
            old_path = unquote(old_path)
            new_path = unquote(new_path)
            
            # 标准化路径，处理不同的路径分隔符
            old_path = os.path.normpath(old_path)
            
            # 确保新路径使用正确的目录分隔符
            dir_path = os.path.dirname(old_path)
            new_filename = os.path.basename(new_path)
            new_path = os.path.join(dir_path, new_filename)
            
            print(f"重命名文件: 从 '{old_path}' 到 '{new_path}'")
            
            if not os.path.exists(old_path):
                print(f"源文件不存在: {old_path}")
                return False
            
            if os.path.exists(new_path):
                print(f"目标文件已存在: {new_path}")
                return False
            
            # 重命名文件
            os.rename(old_path, new_path)
            print(f"文件重命名成功: {old_path} -> {new_path}")
            return True
            
        except Exception as e:
            print(f"重命名BIOS文件出错: {e}")
            return False
            
    @pyqtSlot(str, result=bool)
    def deleteBiosFile(self, file_path):
        """删除BIOS文件"""
        try:
            # 解码URL编码的路径
            file_path = unquote(file_path)
            
            if not os.path.exists(file_path):
                print(f"文件不存在: {file_path}")
                return False
            
            # 删除文件
            os.remove(file_path)
            print(f"文件删除成功: {file_path}")
            return True
            
        except Exception as e:
            print(f"删除BIOS文件出错: {e}")
            return False

def get_resource_path(relative_path):
    """获取资源文件的绝对路径，支持打包后的路径解析"""
    try:
        # PyInstaller创建一个临时文件夹并将路径保存在_MEIPASS中
        base_path = getattr(sys, '_MEIPASS', os.path.dirname(os.path.abspath(__file__)))
        logging.debug(f"资源基础路径: {base_path}")
        abs_path = os.path.join(base_path, relative_path)
        logging.debug(f"资源绝对路径: {abs_path}")
        return abs_path
    except Exception as e:
        logging.exception(f"获取资源路径出错: {str(e)}")
        return os.path.join(os.path.dirname(os.path.abspath(__file__)), relative_path)

def get_exe_path(exe_name):
    """获取可执行文件的绝对路径，考虑打包后的环境"""
    try:
        # 尝试多个可能的位置
        possible_paths = [
            os.path.abspath(exe_name),  # 当前目录
            os.path.join(os.path.dirname(os.path.abspath(__file__)), exe_name),  # 脚本目录
            get_resource_path(exe_name),  # 资源目录
        ]
        
        # 如果是Windows，添加.exe后缀的搜索
        if sys.platform == 'win32' and not exe_name.lower().endswith('.exe'):
            possible_paths.append(os.path.abspath(exe_name + '.exe'))
            possible_paths.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), exe_name + '.exe'))
            possible_paths.append(get_resource_path(exe_name + '.exe'))
        
        # 记录搜索路径
        logging.debug(f"搜索可执行文件 {exe_name} 的可能路径:")
        for idx, path in enumerate(possible_paths):
            logging.debug(f"  {idx+1}. {path} (存在: {os.path.exists(path)})")
        
        # 查找第一个存在的路径
        for path in possible_paths:
            if os.path.exists(path) and os.path.isfile(path):
                logging.debug(f"找到可执行文件: {path}")
                return path
        
        # 如果找不到，返回默认路径并记录警告
        default_path = os.path.abspath(exe_name)
        logging.warning(f"未找到可执行文件 {exe_name}，使用默认路径: {default_path}")
        return default_path
    except Exception as e:
        logging.exception(f"获取可执行文件路径出错: {str(e)}")
        return os.path.abspath(exe_name)

def main():
    """主函数，启动应用程序"""
    try:
        # 设置日志系统
        setup_logging()
        
        logging.info("程序启动")
        logging.debug(f"Python版本: {sys.version}")
        logging.debug(f"操作系统: {sys.platform}")
        logging.debug(f"工作目录: {os.getcwd()}")
        logging.debug(f"程序路径: {sys.executable}")
        logging.debug(f"脚本路径: {os.path.abspath(sys.argv[0])}")
        logging.debug(f"命令行参数: {sys.argv}")
        
        # 检查H2OUVE程序是否存在
        console_exe_path = get_exe_path(CONSOLE_EXE)
        gui_exe_path = get_exe_path(GUI_EXE)
        eze_exe_path = get_exe_path(EZE_EXE)
        fpt_exe_path = get_exe_path(FPT_EXE)
        
        logging.debug(f"检查必要文件是否存在:")
        logging.debug(f"H2OUVE控制台: {console_exe_path}, 存在: {os.path.exists(console_exe_path)}")
        logging.debug(f"H2OUVE GUI: {gui_exe_path}, 存在: {os.path.exists(gui_exe_path)}")
        logging.debug(f"H2OEZE: {eze_exe_path}, 存在: {os.path.exists(eze_exe_path)}")
        logging.debug(f"FPT: {fpt_exe_path}, 存在: {os.path.exists(fpt_exe_path)}")
        
        # 如果没有找到必要的工具，记录错误
        missing_exes = []
        if not os.path.exists(console_exe_path):
            missing_exes.append(f"H2OUVE控制台 ({CONSOLE_EXE})")
        if not os.path.exists(gui_exe_path):
            missing_exes.append(f"H2OUVE GUI ({GUI_EXE})")
        if not os.path.exists(eze_exe_path):
            missing_exes.append(f"H2OEZE ({EZE_EXE})")
        if not os.path.exists(fpt_exe_path):
            missing_exes.append(f"FPT ({FPT_EXE})")
            
        if missing_exes:
            missing_msg = "警告: 以下必要工具未找到: " + ", ".join(missing_exes)
            logging.warning(missing_msg)
            print(missing_msg)
        
        # 检查是否有管理员权限
        if not is_admin():
            logging.info("需要管理员权限，正在重新启动...")
            print("需要管理员权限，正在重新启动...")
            run_as_admin()
            sys.exit(0)
        
        logging.info("以管理员权限运行")
        
        # 确保必要的目录存在
        logging.debug("创建必要的目录")
        for directory in [BACKUP_DIR, EXTRACT_DIR, BIOS_BACKUP_DIR]:
            dir_path = os.path.abspath(directory)
            logging.debug(f"确保目录存在: {dir_path}")
            os.makedirs(dir_path, exist_ok=True)
        
        # 创建应用程序
        logging.debug("创建QGuiApplication实例")
        app = QGuiApplication(sys.argv)
        app.setOrganizationName("InsydeBiosTool")
        app.setApplicationName("Insyde BIOS Toolbox")
        
        # 设置应用图标 - 使用绝对路径
        icon_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icons", "editor_icon.png")
        if os.path.exists(icon_path):
            logging.debug(f"设置应用程序图标: {icon_path}")
            app_icon = QIcon(icon_path)
            app.setWindowIcon(app_icon)
        else:
            logging.warning(f"图标文件不存在: {icon_path}")
            print(f"警告: 图标文件不存在: {icon_path}")
        
        # 设置Windows特有的应用ID 
        if sys.platform == 'win32':
            myappid = 'InsydeBios.Toolbox.1.0'  # 任意字符串，但应该是唯一的
            logging.debug(f"设置Windows应用ID: {myappid}")
            ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(myappid)
        
        logging.debug("创建QML引擎")
        # 创建QML引擎
        engine = QQmlApplicationEngine()
        
        # 创建后端对象
        logging.debug("创建后端对象")
        backend = BiosToolBackend()
        
        # 将后端对象暴露给QML
        logging.debug("将后端对象暴露给QML")
        engine.rootContext().setContextProperty("backend", backend)
        
        # 添加QML导入路径
        logging.debug("添加QML导入路径")
        engine.addImportPath("qrc:/")
        
        # 加载QML文件
        qml_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "gui", "main.qml")
        logging.info(f"加载QML文件: {qml_file}")
        engine.load(QUrl.fromLocalFile(qml_file))
        
        # 检查是否成功加载QML
        if not engine.rootObjects():
            logging.error("无法加载QML文件")
            sys.exit(-1)
        
        logging.info("启动应用程序")
        # 启动应用程序
        sys.exit(app.exec_())
    except Exception as e:
        logging.exception(f"程序启动失败: {str(e)}")
        print(f"程序启动失败: {str(e)}")
        sys.exit(-1)

if __name__ == "__main__":
    main() 