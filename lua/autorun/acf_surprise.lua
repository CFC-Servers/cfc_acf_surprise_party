local surpriseSounds = {
    "acf_surprise/surprise1.wav",
    "acf_surprise/surprise2.wav",
    "acf_surprise/surprise2.wav",
    "acf_surprise/surprise2.wav",
    "acf_surprise/surprise3.wav",
    "acf_surprise/surprise4.wav",
    "acf_surprise/surprise5.wav",
    "acf_surprise/surprise6.wav",
    "acf_surprise/surprise7.wav",
    "acf_surprise/surprise8.wav",
    "acf_surprise/surprise9.wav",
    "acf_surprise/surprise9.wav",
    "acf_surprise/surprise9.wav",
    "acf_surprise/surprise9.wav",
    "acf_surprise/surprise10.wav",
    "acf_surprise/surprise11.wav",
    "acf_surprise/surprise12.wav",
    "acf_surprise/surprise13.wav",
    "acf_surprise/surprise14.wav",
    "acf_surprise/surprise14.wav",
    "acf_surprise/surprise14.wav",
    "acf_surprise/surprise14.wav",
    "acf_surprise/surprise14.wav",
}

local surpriseSoundsCount = #surpriseSounds


if CLIENT then
    local Rand = math.Rand
    local random = math.random
    local Clamp = math.Clamp
    local ceil = math.ceil

    local CreateClientProp = ents.CreateClientProp
    local IsValid = IsValid
    local rawget = rawget

    local maxConfetti = 1650
    local totalConfetti = 0
    local confettiLifetime = 2.5

    local function playSurpriseSoundOn( ent, origin )
        local soundPath = rawget( surpriseSounds, random( 1, surpriseSoundsCount ) )
        local pitch = Rand( 75, 110 )

        local soundEnt = CreateClientProp( "models/props_junk/PopCan01a.mdl" )
        soundEnt:SetNoDraw( true )
        soundEnt:SetNotSolid( true )
        soundEnt:SetPos( origin + ( Vector( Rand( -1, 1 ), Rand( -1, 1 ), Rand( -1, 1 ) ) * Rand( 1, 10 ) ) )
        soundEnt:SetParent( ent )
        soundEnt:Spawn()
        soundEnt:CallOnRemove( "StopSurpriseSound", function()
            soundEnt:StopSound( soundPath )
        end )

        timer.Simple( Rand( 0, 1 ), function()
            if not IsValid( soundEnt ) then return end

            soundEnt:EmitSound( soundPath, 130, pitch, 1, CHAN_WEAPON )
        end )

        timer.Simple( 2.5, function()
            if not IsValid( soundEnt ) then return end
            soundEnt:Remove()
        end )

        return soundEnt
    end

    local TIGHTNESS         = 300
    local HORIZONTAL_SPREAD = 80
    local VERTICAL_SPREAD   = 80

    local getRandomizedVelocity = function( original )
        local x = TIGHTNESS
        local y = random( -HORIZONTAL_SPREAD, HORIZONTAL_SPREAD )
        local z = random( -VERTICAL_SPREAD, VERTICAL_SPREAD )

        local newVel = Vector( x, y, z )

        newVel:Rotate( original:Angle() )
        newVel:Normalize()

        return newVel
    end


    local colors = {
        Color( 255, 0, 0 ),
        Color( 0, 255, 0 ),
        Color( 0, 0, 255 ),
        Color( 255, 212, 229 ),
        Color( 189, 232, 239 ),
        Color( 183, 215, 132 ),
        Color( 105, 255, 185 ),
        Color( 118, 236, 251 ),
        Color( 193, 253, 160 ),
        Color( 242, 152, 244 ),
        Color( 147, 134, 230 )
    }

    local colorCount = #colors

    function confetti( particleCount, startPos, direction )
        local emitter = ParticleEmitter( startPos, true )

        for _ = 0, particleCount do
            local randomColor = rawget( colors, random( 1, colorCount ) )

            local particle = emitter:Add( "particles/balloon_bit", startPos )
            if particle then

                -- TODO: Modify by power
                particle:SetVelocity( getRandomizedVelocity( direction )  * Rand( 350, 1800 ) )
                particle:SetVelocityScale( true )

                particle:SetLifeTime( 0 )
                particle:SetDieTime( confettiLifetime )

                particle:SetStartAlpha( 255 )
                particle:SetEndAlpha( 255 )

                local Size = Rand( 1, 5 )
                particle:SetStartSize( Size )
                particle:SetEndSize( 0 )

                particle:SetRoll( Rand( 0, 360 ) )
                particle:SetRollDelta( Rand( -2, 2 ) )

                particle:SetAirResistance( 45 )
                particle:SetGravity( Vector( 0, 0, -75 ) )

                particle:SetColor( randomColor.r, randomColor.g, randomColor.b )

                particle:SetCollide( true )

                particle:SetBounce( 1 )
                particle:SetLighting( false )
            end

        end

        emitter:Finish()
    end

    local function surpriseReceiver()
        local gun = net.ReadEntity()
        if not IsValid( gun ) then return end

        local reloadTime = net.ReadFloat()
        local forward = gun:GetAngles():Forward()

        local maxCount = math.min( maxConfetti - totalConfetti, 275 )
        local count = Clamp( reloadTime * 225, 0, maxCount )

        local muzzle = gun:LookupAttachment( "muzzle" )
        if not muzzle then return false end

        muzzle = gun:GetAttachment( muzzle )
        if not muzzle then return end

        local pos = muzzle.Pos

        confetti( count, pos, forward )
        totalConfetti = totalConfetti + count
        timer.Simple( confettiLifetime, function()
            totalConfetti = math.max( 0, totalConfetti - count )
        end )

        if reloadTime < 2.75 then return end

        local maxSounds = 2 + ( Clamp( ceil( reloadTime ), 1, 5 ) )
        local soundCount = random( 2, maxSounds )
        local soundEnts = {}

        local randomStartSound = rawget( surpriseSounds, random( 1, surpriseSoundsCount ) )
        timer.Simple( 0.025, function()
            gun:EmitSound( randomStartSound, 130, pitch, 1, CHAN_WEAPON )
        end )

        for i = 1, soundCount - 1 do
            rawset( soundEnts, i, playSurpriseSoundOn( gun, pos ) )
        end

        gun:CallOnRemove( "SurpriseStopSounds", function()
            gun:StopSound( randomStartSound )
            for i = 1, soundCount do
                local soundEnt = rawget( soundEnts, i )

                if IsValid( soundEnt ) then
                    soundEnt:Remove()
                end
            end
        end )
    end

    net.Receive( "acf_surprise", surpriseReceiver )
end

if SERVER then
    util.AddNetworkString( "acf_surprise" )
    local toggle = CreateConVar( "acf_surprise", "0", FCVAR_ARCHIVE, "Enable/disable the ACF surprise feature" )

    for _, soundPath in ipairs( surpriseSounds ) do
        resource.AddSingleFile( soundPath )
    end

    hook.Add( "ACF_FireShell", "Confet", function( gun )
        if not toggle:GetBool() then return end

        if gun.Owner and gun.Owner:IsInBuild() then return end
        if gun:GetClass() == "acf_piledriver" then return false end

        local recipients = RecipientFilter()
        recipients:AddPVS( gun:GetPos() )

        for _, ply in ipairs( recipients:GetPlayers() ) do
            if ply:IsInBuild() then recipients:RemovePlayer( ply ) end
        end

        local now = CurTime()
        if ( gun.lastConfetti or 0 ) < now - 0.5 then
            net.Start( "acf_surprise" )
            net.WriteEntity( gun )
            net.WriteFloat( gun.ReloadTime or 1.5 )
            net.Send( recipients )
            gun.lastConfetti = now
        end

        if gun.MuzzleEffect then gun:MuzzleEffect() end
        if gun.Recoil then gun:Recoil() end

        if gun.MagSize then -- Mag-fed/Automatically loaded
            if gun.CurrentShot then
                gun.CurrentShot = gun.CurrentShot - 1

                if gun.CurrentShot > 0 then -- Not empty
                    if gun.Chamber then gun:Chamber( gun.Cyclic ) end
                else -- Reload the magazine
                    if gun.Load then gun:Load() end
                end
            end

        else -- Single-shot/Manually loaded
            if gun.CurrentShot then gun.CurrentShot = 0 end
            if gun.Chamber then gun:Chamber() end
        end

        return false
    end )
end
