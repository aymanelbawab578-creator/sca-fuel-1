import zipfile
import shutil
import os
zip_path = r" C:\\Users\\FIRST\\Downloads\\flutter_windows_3.44.2-stable.zip\
dest = r\C:\\Users\\FIRST\\Desktop\\sca\\frontend\\flutter_sdk\
shutil.rmtree(dest, ignore_errors=True)
os.makedirs(dest, exist_ok=True)
with zipfile.ZipFile(zip_path) as z:
 z.extractall(dest)
 print(\extracted\, len(z.namelist()))
