# 自动签到
自动签到shell脚本，部署在软路由或服务器上，该项目支持签到完bark推送到手机端

目前仅支持百度贴吧

目录结构：
```
|-- qiandao_data

  |-- config
   
    |-- bark
      
      |-- bark.txt  # bark配置
      
    |-- cookies
      
      |-- baidu.txt  # baidu cookie配置
      
  |-- logs
  
    |-- baidu  # baidu相关的日志文件
    
    |-- main  # 脚本相关的日志文件
   
  |-- temp  # 签到过程中生成的临时文件
   
|-- qiandao.sh
```

# 签到配置

## Cookie配置

在相关主页取得cookie后，在`qiandao_data/config/cookies`下新建相关文本，目前仅支持baidu，即新建baidu.txt，该文档中内容应有且只有一行，且内容为cookie。

## Bark配置

在配置完Bark服务器和手机客户端后，可从手机端得到一个推送url，该url格式为`https://推送服务器/设备码/`。

在`qiandao_data/config/bark`下新建一个`bark.txt`，该文档中内容应有且只有一行，且内容为推送url，且改url以'/'结尾。

# 使用

通过bash调用即可，在第一次运行后会自动生成如上目录，而后即可进行手动配置。配置完成后再次运行即可自动签到。

```
bash qiandao.sh
```

可通过cron实现定时，解放签到
