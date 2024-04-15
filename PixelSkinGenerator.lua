function FindLayer(sprite, targetLayer)
    for _,layer in ipairs(sprite.layers) do
        if layer.name == targetLayer then
            return layer
        end
    end
    return nil
end

function ProcessSkin(sprite, data)
    local group = FindLayer(sprite, "Skins")
    if not group then
        group = sprite:newGroup()
        group.name = "Skins"
    end

    local layer = FindLayer(sprite, data.BaseLayer)
    if not layer then
        return app.alert(sprite.filename .. " Error - base skin layer does not exist")
    end

    local newLayer = sprite:newLayer()
    newLayer.name = data.NewLayer
    newLayer.parent = group

    for _,cel in ipairs(layer.cels) do
        local copyImage = cel.image:clone()
        local newCel = sprite:newCel(newLayer, cel.frame, copyImage, cel.position)

        app.activeCel = newCel
        app.command.ReplaceColor { ui = false, channels = FilterChannels.RGBA, from = data.FromDarkest, to = data.ToDarkest, tolerance = 0 }
        app.command.ReplaceColor { ui = false, channels = FilterChannels.RGBA, from = data.FromLigthest, to = data.ToLigthest, tolerance = 0 }        
    end
end

function RemoveSkin(sprite)
    local group = FindLayer(sprite, "Skins")
    if not group then
        return
    end

    app.activeLayer = group    
    app.command.RemoveLayer()
end

function ProcessFiles(filesToProcess, data, remove)    
    for _, file in ipairs(filesToProcess) do        
        app.command.OpenFile { filename = file }

        -- Begin process
        local sprite = app.activeSprite
        if not sprite then 
            return app.alert("There is no active sprite")
        end

        if remove then
            RemoveSkin(sprite)
        else
            ProcessSkin(sprite, data)
        end

        --End process
        app.command.SaveFile()
        app.command.CloseFile { quitting = false }
    end
end



app.transaction(
    function()
        local sprite = app.activeSprite
        if not sprite then 
            return app.alert("There is no active sprite")
        end

        local dlg = Dialog()
        dlg:check { id = "AllFiles", label = "Process all aseprite files at the current location"}            
            :separator { label = "Base skin" }            
            :entry { id = "BaseLayer", label = "Insert the base skin layer name", text = "BaseSkin" }
            :color { id = "FromLigthest", label = "From Ligthest", color =  Color { r=70, g=130, b=50, a=255} }
            :color { id = "FromDarkest", label = "From Darkest", color =  Color { r=37, g=86, b=46, a=255}  }
            :separator { label = "New skin" }   
            :entry { id = "NewLayer", label = "Insert the new skin layer name" }
            :color { id = "ToLigthest", label = "To Ligthest" }
            :color { id = "ToDarkest", label = "To Darkest" }
            :separator()
            :button { id="ok", text="Ok" }
            :button { id="cancel", text="Cancel" }
            :button { id="remove", text="Remove Skin Group" }
            :show()

        local data = dlg.data
        if data.cancel then
            return
        end

        app.command.CloseFile { quitting = false }

        local files = {}        
        if data.AllFiles == true then
            for i, filename in pairs(app.fs.listFiles(app.fs.filePath(sprite.filename))) do
                if app.fs.fileExtension(filename) == "aseprite" then
                    files[i] = app.fs.joinPath(app.fs.filePath(sprite.filename), filename)
                end
            end
        else
            files[1] = app.fs.filePath(sprite.filename) .. app.fs.pathSeparator .. app.fs.fileName(sprite.filename)
        end

        ProcessFiles(files, data, data.remove)
    end
)