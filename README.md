## Hugo

1. Install Hugo
   ```bash
   brew install hugo
    ```
2. Create a new site
   ```bash
   hugo new site quickstart
   ```   
3. Add a Theme
4. Start the Hugo server
    ```bash
    hugo server
    ```
5. Build static pages
    ```bash
    hugo -D
    ```
## Theme

### Update theme
在主项目目录下打开命令行工具执行命令 `git rm --cached path_to_submodule` 删除指定模块的文件

打开主项目目录下 .gitmodules文件 删除如下类似内容:
mac下使用命令 vim .gitmodules 可打开vim编辑
```
[submodule "path_to_submodule"]
path = path_to_submodule
url = https://github.com/path_to_submodule
```
打开主项目目录下 .git/config 文件 删除如下内容:
同样可使用vim编辑
```
[submodule "path_to_submodule"]
url = https://github.com/path_to_submodule
```
使用命令行工具执行命令：`rm -rf .git/modules/path_to_submodule` 删除.git下的缓存模块