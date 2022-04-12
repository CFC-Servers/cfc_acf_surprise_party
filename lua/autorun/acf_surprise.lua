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

    local TIGHTNESS         = 300
    local HORIZONTAL_SPREAD = 80
    local VERTICAL_SPREAD   = 80

    local getRandomizedVelocity = function(original)
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
            local randomColor = colors[random( 1, colorCount )]

            local particle = emitter:Add( "particles/balloon_bit", startPos )
            if ( particle ) then

                -- TODO: Modify by power
                particle:SetVelocity( getRandomizedVelocity( direction )  * Rand( 350, 1800 ) )
                particle:SetVelocityScale( true )

                particle:SetLifeTime( 0 )
                particle:SetDieTime( 2.5 )

                particle:SetStartAlpha( 255 )
                particle:SetEndAlpha( 255 )

                local Size = Rand( 1, 5 )
                particle:SetStartSize( Size )
                particle:SetEndSize( 0 )

                particle:SetRoll( Rand( 0, 360 ) )
                particle:SetRollDelta( Rand( -2, 2 ) )

                particle:SetAirResistance( 10 )
                particle:SetGravity( Vector( 0, 0, -50 ) )

                particle:SetColor( randomColor.r, randomColor.g, randomColor.b )

                particle:SetCollide( true )

                particle:SetBounce( 1 )
                particle:SetLighting( true )

            end

        end

        emitter:Finish()
    end

    net.Receive( "acf_surprise", function()
        local gun = net.ReadEntity()
        local reloadTime = net.ReadUInt( 5 )
        local count = Clamp( reloadTime * 225, 1, 600 )
        local forward = gun:GetAngles():Forward()
        local pos = gun:GetAttachment(gun:LookupAttachment("muzzle")).Pos
        confetti( count, pos, forward )

        if reloadTime > 3.5 then
            for _ = 1, random( 2, 4 ) do
                local soundPath = surpriseSounds[random( 1, surpriseSoundsCount )]
                local pitch = Rand( 80, 115 )

                timer.Simple( Rand( 0, 0.6 ), function()
                    sound.Play( soundPath, pos, 80, pitch, 1 )
                end )
            end
        end
    end )
end

if SERVER then
    util.AddNetworkString( "acf_surprise" )

    for _, soundPath in ipairs( surpriseSounds ) do
        resource.AddSingleFile( soundPath )
    end

    hook.Add( "ACF_FireShell", "Confet", function( gun )

        local recipients = RecipientFilter()
        recipients:AddPVS( gun:GetPos() )
        PrintTable( recipients:GetPlayers() )

        for _, ply in ipairs( recipients:GetPlayers() ) do
            if ply:isInBuild() then recipients:RemovePlayer( ply ) end
        end

        net.Start( "acf_surprise" )
        net.WriteEntity( gun )
        net.WriteUInt( gun.ReloadTime, 5 )
        net.Send( recipients )

        gun:MuzzleEffect()
        gun:Recoil()
        if gun.MagSize then -- Mag-fed/Automatically loaded
            gun.CurrentShot = gun.CurrentShot - 1

            if gun.CurrentShot > 0 then -- Not empty
                gun:Chamber(gun.Cyclic)
            else -- Reload the magazine
                gun:Load()
            end
        else -- Single-shot/Manually loaded
            gun.CurrentShot = 0 -- We only have one shot, so shooting means we're at 0
            gun:Chamber()
        end
        return false
    end )
end
