classdef "RoomInfo" {
    int "roomId" "房间ID",
}

classdef "TableInfo" {
    int "tableId" "桌子ID",
    string "password" "密码",
    class.RoomInfo "roomInfo" "房间信息"
}

mod "demo" "测试模块"
{
 [101] = api "login" "登录接口"
 {
  req {
      int "playerId" "玩家ID",
      string "password" "密码"
  },
  res {
      int "playerId" "玩家ID"
  }
},
[102] = api "enterTable" "进入桌子"
 {
  req {
      int "tableId" "桌子ID",
      string "password" "密码"
  },
  res {
      class.TableInfo "tableInfo" "桌子信息"
  }
},
[103] = api "notify" "通知"
 {
  res {
      int "msgId" "信息ID",
      string "msg" "信息"
  }
}
}



