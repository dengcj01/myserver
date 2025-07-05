--keys:id|name|type|part|attachment|pictureName|showPictureName|isCost|icon|resource_id|CostNum|
local characterAppearance={
[998]={id=998,name="默认男套装",type=4,part=0,attachment="[1,2,3]",pictureName="[1,2,3]",showPictureName="",isCost=0,icon="morennan",resource_id="master_m",CostNum=0,},
[999]={id=999,name="默认女套装",type=5,part=0,attachment="[4,5,6,7]",pictureName="[4,5,6,7]",showPictureName="",isCost=0,icon="morennv",resource_id="master_f",CostNum=0,},
[1]={id=1,name="默认肤色男",type=1,part=1,attachment="[Su_tou,Su_zuoxiaobi,Su_zuodabi,Su_xiong,Su_youdabi,Su_kua,Su_zuodatui,Su_zuoxiaotui,Su_youtui,Su_youdatui,Su_youxiaobi,Su_shadow]",pictureName="[Su_tou,Su_zuoxiaobi,Su_zuodabi,Su_xiong,Su_youdabi,Su_kua,Su_zuodatui,Su_zuoxiaotui,Su_youtui,Su_youdatui,Su_youxiaobi,Su_shadow]",showPictureName="",isCost=0,icon="",resource_id="",CostNum=0,},
[2]={id=2,name="默认眼睛男",type=1,part=4,attachment="[youzhengyan,zuozhengyan]",pictureName="[youzhengyan,zuozhengyan]",showPictureName="",isCost=0,icon="",resource_id="",CostNum=0,},
[3]={id=3,name="默认套装男",type=1,part=10,attachment="[toufa1,toufa2,dingfa,liantouying,zhui1,zhui2,zhui3,zhui4,zhui5,beitoua,touliu1,touliu2,huwan1,huwan2,zuoyiling,youyiling,zuodabi,youdabi,piaodai1,piaodai2,ying,ying2,shangyi,yaodai,jin,qunbai1,qunbai2,zuodatui,zuoxiaotui,youdatui,youxiaotui,qunaaa,qunbbb]",pictureName="[toufa1,toufa2,dingfa,liantouying,zhui1,zhui2,zhui3,zhui4,zhui5,beitoua,touliu1,touliu2,huwan1,huwan2,zuoyiling,youyiling,zuodabi,youdabi,piaodai1,piaodai2,ying,ying2,shangyi,yaodai,jin,qunbai1,qunbai2,zuodatui,zuoxiaotui,youdatui,youxiaotui,qunaaa,qunbbb]",showPictureName="morennan",isCost=0,icon="",resource_id="",CostNum=0,},
[4]={id=4,name="默认肤色女",type=2,part=1,attachment="[Su_tou,Su_zuoxiaobi,Su_zuodabi,Su_zuodatui,Su_zuoxiaotui,Su_kua,Su_youdatui,Su_shenti,Su_youxiaotui,Su_youxiaobi,Su_youdabi,Su_shadow]",pictureName="[Su_tou,Su_zuoxiaobi,Su_zuodabi,Su_zuodatui,Su_zuoxiaotui,Su_kua,Su_youdatui,Su_shenti,Su_youxiaotui,Su_youxiaobi,Su_youdabi,Su_shadow]",showPictureName="",isCost=0,icon="",resource_id="",CostNum=0,},
[5]={id=5,name="默认眼睛女",type=2,part=4,attachment="[youzhengyan,zuozhengyan]",pictureName="[youzhengyan,zuozhengyan]",showPictureName="",isCost=0,icon="",resource_id="",CostNum=0,},
[6]={id=6,name="默认嘴女",type=2,part=5,attachment="[zuoba]",pictureName="[zuoba]",showPictureName="",isCost=0,icon="",resource_id="",CostNum=0,},
[7]={id=7,name="默认套装女",type=2,part=10,attachment="[faxing1,faxing2,faxing3,faxing4,liuhai1,liuhai2,dingfa,faying1,faying2,erzhui,shangyia,zuoling,zuojianjia,zuoxiu,zuoxiaobi,zuoxiubei,youling,youjianjia,youxiaobi,youxiu,youxiubei,yaobu1,yaobu2,zhongqun1,zuobanqun,youbanqun,beiziquna,zuoxie,youxie,zhui1,zhui2,zhui3,zhui4,zhui5,zhui6,jinshi1,jinshi2,zhongsheng]",pictureName="[faxing1,faxing2,faxing3,faxing4,liuhai1,liuhai2,dingfa,faying1,faying2,erzhui,shangyia,zuoling,zuojianjia,zuoxiu,zuoxiaobi,zuoxiubei,youling,youjianjia,youxiaobi,youxiu,youxiubei,yaobu1,yaobu2,zhongqun1,zuobanqun,youbanqun,beiziquna,zuoxie,youxie,zhui1,zhui2,zhui3,zhui4,zhui5,zhui6,jinshi1,jinshi2,zhongsheng]",showPictureName="morennv",isCost=0,icon="",resource_id="",CostNum=0,},

}

local default_value = {
    name = "默认男套装",
type = 4,
part = 0,
attachment = "[1,2,3]",
pictureName = "[1,2,3]",
showPictureName = "",
isCost = 0,
icon = "morennan",
resource_id = "master_m",
CostNum = 0,

}
local setmetatable = setmetatable
local metatable = nil
local function __newindex(t, k, v)
    setmetatable(t, nil)
    t[k] = v
    --NE.LOG_ERROR("请不要修改表格字段!")
    setmetatable(t, metatable)
end
metatable = {__index = default_value, __newindex = __newindex}
for _, v in pairs(characterAppearance) do
    setmetatable(v, metatable)
end
 
return characterAppearance
