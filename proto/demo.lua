comment [[
    这是一段
    多行文本
]]

class "RoomInfo" {
    int "roomId" "房间ID",
}

class "TableInfo" {
    int "tableId" "桌子ID",
    boolean "isVIP" "是否VIP房",
    String "password" "密码",
    class.RoomInfo "roomInfo" "房间信息"
}

mod "demo" "测试模块" {
    [101] = api "login" "登录接口" {
        req {
            int "playerId" "玩家ID",
            String "password" "密码"
        },
        res {
            int "playerId" "玩家ID"
        }
    },
    [102] = api "enterTable" "进入桌子" {
        req {
            int "tableId" "桌子ID",
            String "password" "密码"
        },
        res {
            class.TableInfo "tableInfo" "桌子信息"
        }
    },
    [103] = api "notify" "通知" {
        res {
            int "msgId" "信息ID",
            String "msg" "信息"
        }
    },
    [104] = api "showCard" "出牌" {
        req {
            int "tableId" "桌子ID",
            list("Integer") "cards" "手牌"
        },
        res {
            list("Integer") "cards" "手牌"
        }
    },
}



