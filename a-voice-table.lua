--Define what actions play what voice clips
--If an action has more than one voice clip, put those clips inside a table
--CHAR_SOUND_SNORING3 requires two or three voice clips to work properly...
--but you can omit it if your character does not sleep-talk
SONIC_VOICETABLE = {
    [CHAR_SOUND_ATTACKED] = {'sonic-ow.mp3', 'sonic-uuurgh.mp3'},
    [CHAR_SOUND_COUGHING1] = 'sonic-cough.mp3',
    [CHAR_SOUND_COUGHING2] = 'sonic-cough-2.mp3',
    [CHAR_SOUND_COUGHING3] = 'sonic-cough-3.mp3',
    [CHAR_SOUND_DOH] = 'sonic-oof.mp3',
    [CHAR_SOUND_DROWNING] = 'sonic-drowning.mp3',
    [CHAR_SOUND_DYING] = 'sonic-dying.mp3',
    [CHAR_SOUND_EEUH] = 'sonic-eeyuh.mp3',
    --[CHAR_SOUND_GAME_OVER] = 'Game_Over.ogg',
    [CHAR_SOUND_GROUND_POUND_WAH] = 'sonic-wuh.mp3',
    [CHAR_SOUND_HAHA] = {'sonic-haha.mp3', 'sonic-haha2.mp3'},
    [CHAR_SOUND_HAHA_2] = {'sonic-haha.mp3', 'sonic-haha2.mp3'},
    [CHAR_SOUND_HELLO] = 'sonic-hey.mp3',
    [CHAR_SOUND_HERE_WE_GO] = 'sonic-here-we-go.mp3',
    [CHAR_SOUND_HOOHOO] = 'sonic-hah2.mp3',
    [CHAR_SOUND_HRMM] = 'sonic-pick-up.mp3',
    [CHAR_SOUND_IMA_TIRED] = 'sonic-phew-im-beat.mp3',
    [CHAR_SOUND_LETS_A_GO] = 'sonic-ok.mp3',
    [CHAR_SOUND_MAMA_MIA] = 'sonic-aw-man.mp3',
    --[CHAR_SOUND_OKEY_DOKEY] = 'Okie_Dokie.ogg',
    [CHAR_SOUND_ON_FIRE] = 'sonic-burning.mp3',
    [CHAR_SOUND_OOOF] = 'sonic-ow2.mp3',
    [CHAR_SOUND_OOOF2] = 'sonic-ow2.mp3',
    [CHAR_SOUND_PANTING] = {'sonic-huff.mp3', 'sonic-huff-2.mp3'},
    --[CHAR_SOUND_PANTING_COLD] = 'Panting_Low_Energy.ogg',
    --[CHAR_SOUND_PRESS_START_TO_PLAY] = 'Press_Start_to_Play.ogg',
    [CHAR_SOUND_PUNCH_HOO] = 'sonic-yah.mp3',
    [CHAR_SOUND_PUNCH_WAH] = 'sonic-hup.mp3',
    [CHAR_SOUND_PUNCH_YAH] = 'sonic-hah.mp3',
    [CHAR_SOUND_SNORING1] = 'sonic-snore.mp3',
    [CHAR_SOUND_SNORING2] = 'sonic-snore-2.mp3',
    [CHAR_SOUND_SNORING3] = {'sonic-snore-3.mp3', 'sonic-snore-2.mp3'},
    [CHAR_SOUND_SO_LONGA_BOWSER] = 'sonic-so-long-sucker.mp3',
    [CHAR_SOUND_TWIRL_BOUNCE] = 'sonic-woohoo.mp3',
    [CHAR_SOUND_UH] = 'sonic-oof-low-energy.mp3',
    [CHAR_SOUND_UH2] = 'sonic-oof-low-energy.mp3',
    [CHAR_SOUND_UH2_2] = 'sonic-oof-low-energy.mp3',
    [CHAR_SOUND_WAAAOOOW] = 'sonic-scream.mp3',
    [CHAR_SOUND_WAH2] = 'sonic-wuh.mp3',
    [CHAR_SOUND_WHOA] = 'sonic-woah.mp3',
    [CHAR_SOUND_YAHOO] = 'sonic-woohoo.mp3',
    [CHAR_SOUND_YAHOO_WAHA_YIPPEE] = {'sonic-woohoo.mp3', 'sonic-aw-yeah.mp3'},
    [CHAR_SOUND_YAH_WAH_HOO] = {'sonic-hup.mp3', 'sonic-wuh.mp3', 'sonic-hah.mp3'},
    [CHAR_SOUND_YAWNING] = 'sonic-yawn.mp3',
}

AMY_VOICETABLE = {
    [CHAR_SOUND_ATTACKED] = {'amy-oof.mp3', 'amy-uagh.mp3'},
    [CHAR_SOUND_COUGHING1] = 'amy-cough.mp3',
    [CHAR_SOUND_COUGHING2] = 'amy-cough-2.mp3',
    [CHAR_SOUND_COUGHING3] = 'amy-cough-2.mp3',
    [CHAR_SOUND_DOH] = 'amy-drats.mp3',
    [CHAR_SOUND_DROWNING] = 'amy-drown.mp3',
    --[CHAR_SOUND_DYING] = 'sonic-dying.mp3',
    [CHAR_SOUND_EEUH] = 'amy-pick-up.mp3',
    --[CHAR_SOUND_GAME_OVER] = 'Game_Over.ogg',
    [CHAR_SOUND_GROUND_POUND_WAH] = 'amy-wah.mp3',
    [CHAR_SOUND_HAHA] = {'amy-haha.mp3'},
    [CHAR_SOUND_HAHA_2] = {'amy-haha.mp3'},
    [CHAR_SOUND_HELLO] = 'amy-hi-there.mp3',
    [CHAR_SOUND_HERE_WE_GO] = 'amy-here-we-go.mp3',
    [CHAR_SOUND_HOOHOO] = 'amy-yah.mp3',
    [CHAR_SOUND_HRMM] = 'amy-pick-up.mp3',
    [CHAR_SOUND_IMA_TIRED] = 'amy-im-tired.mp3',
    [CHAR_SOUND_LETS_A_GO] = 'amy-lets-go.mp3',
    [CHAR_SOUND_MAMA_MIA] = 'amy-oh-no.mp3',
    --[CHAR_SOUND_OKEY_DOKEY] = 'Okie_Dokie.ogg',
    [CHAR_SOUND_ON_FIRE] = 'amy-ow-ow-ow.mp3',
    [CHAR_SOUND_OOOF] = 'amy-uagh.mp3',
    [CHAR_SOUND_OOOF2] = 'amy-uagh.mp3',
    [CHAR_SOUND_PANTING] = {'amy-huff.mp3', 'amy-huff-2.mp3'},
    --[CHAR_SOUND_PANTING_COLD] = 'Panting_Low_Energy.ogg',
    --[CHAR_SOUND_PRESS_START_TO_PLAY] = 'Press_Start_to_Play.ogg',
    [CHAR_SOUND_PUNCH_HOO] = 'amy-wah.mp3',
    [CHAR_SOUND_PUNCH_WAH] = 'amy-wah.mp3',
    [CHAR_SOUND_PUNCH_YAH] = 'amy-yah.mp3',
    --[CHAR_SOUND_SNORING1] = 'sonic-snore.mp3',
    --[CHAR_SOUND_SNORING2] = 'sonic-snore-2.mp3',
    --[CHAR_SOUND_SNORING3] = {'sonic-snore-3.mp3', 'sonic-snore-2.mp3'},
    [CHAR_SOUND_SO_LONGA_BOWSER] = 'amy-seeyalater.mp3',
    [CHAR_SOUND_TWIRL_BOUNCE] = 'amy-boing.mp3',
    [CHAR_SOUND_UH] = 'amy-ungh.mp3',
    [CHAR_SOUND_UH2] = 'amy-ungh.mp3',
    [CHAR_SOUND_UH2_2] = 'amy-ungh.mp3',
    --[CHAR_SOUND_WAAAOOOW] = 'sonic-scream.mp3',
    [CHAR_SOUND_WAH2] = 'amy-wah.mp3',
    [CHAR_SOUND_WHOA] = 'amy-woah.mp3',
    [CHAR_SOUND_YAHOO] = 'amy-yipee.mp3',
    [CHAR_SOUND_YAHOO_WAHA_YIPPEE] = {'amy-yipee.mp3', 'amy-woohoo.mp3', 'amy-woo.mp3'},
    [CHAR_SOUND_YAH_WAH_HOO] = {'amy-yah.mp3'},
    [CHAR_SOUND_YAWNING] = 'amy-yawn.mp3',
}