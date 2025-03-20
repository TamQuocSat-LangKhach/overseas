local os__hongju = fk.CreateSkill {
  name = "os__hongju"
}

Fk:loadTranslationTable{
  ['os__hongju'] = '鸿举',
  ['$os__glory'] = '荣',
  ['#os__hongju-exchange'] = '鸿举：可用任意张手牌替换等量的“荣”',
  ['os__qingce'] = '清侧',
  ['os__hongju_saotao'] = '减1点体力上限，获得〖扫讨〗（锁定技，你使用的【杀】和普通锦囊牌不能被响应）',
  ['os__saotao'] = '扫讨',
  [':os__hongju'] = '觉醒技，准备阶段开始时，若“荣”的数量不小于3，则你摸等于“荣”数量的牌，然后用任意张手牌替换等量的“荣”，然后获得〖清侧〗并选择是否减1点体力上限获得技能〖扫讨〗。',
  ['$os__hongju1'] = '鸿飞冲云天，魂归入魏土。',
  ['$os__hongju2'] = '吾负淮阴之才，岂能受你摆布！',
}

os__hongju:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__hongju) and
      player.phase == Player.Start and
      player:usedSkillTimes(os__hongju.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player)
    return #player:getPile("$os__glory") > 2
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    if #player:getPile("$os__glory") > 0 then
      player:drawCards(#player:getPile("$os__glory"), os__hongju.name)
      if not player.dead and #player:getPile("$os__glory") > 0 and not player:isKongcheng() then
        local cids = room:askToArrangeCards(player, {
          skill_name = os__hongju.name,
          card_map = {player:getPile("$os__glory"), player:getCardIds(Player.Hand)},
          area_names = {"$os__glory", "$Hand"},
          prompt = "#os__hongju-exchange",
          free_arrange = true
        })
        U.swapCardsWithPile(player, cids[1], cids[2], os__hongju.name, "$os__glory")
      end
    end
    room:handleAddLoseSkills(player, "os__qingce", nil)
    local choices = {"os__hongju_saotao", "Cancel"}
    if room:askToChoice(player, {
      choices = choices,
      skill_name = os__hongju.name
    }) == "os__hongju_saotao" then
      room:changeMaxHp(player, -1)
      room:handleAddLoseSkills(player, "os__saotao", nil)
    end
  end,
})

return os__hongju
