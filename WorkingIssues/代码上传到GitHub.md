## 代码上传到GitHub

* 1、创建本地项目
* 2、cd进到刚创建的项目
* 3、创建本地仓库： git init
* 4、执行add操作：git add .
* 5、执行commit操作: git commit -m "提交说明"
* 6、在GitHub上面创建Repository
* 7、创建好Repository之后，将创建好的远程仓库与本地仓库关联起来：git remote add origin + 远程仓地址
* 8、关联起来之后，执行一下pull操作（报错也不管）：git pull origin main
* 9、设置main对应远程仓库的main分支 (这一步可以跳过，直接进行第10步)
git branch --set-upstream main origin/main
（设置完之后，下次提交的时候直接 git pull 或者git push就行，不然每次都需要 git pull(push) origin main）
* 10、将代码提交到GitHub：git push -u origin main

