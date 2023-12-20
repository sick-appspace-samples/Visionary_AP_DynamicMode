--[[----------------------------------------------------------------------------

  Application Name: Visionary_AP_DynamicMode

  Summary:
  Implement the dynamic filter and see the results

  Description:
  Dynamic mode is a filter which detects differences between images
  and removes pixels which change more than a certain amount between
  the two images. This filter is implemented and applied to the live images
  the camera takes.

  How to run:
  Start by running the app (F5) or debugging (F7+F10).
  Set a breakpoint on the first row inside the main function to debug step-by-step.
  See the results in the viewer on the DevicePage.


------------------------------------------------------------------------------]]

--Start of Global Scope---------------------------------------------------------

-- Variables, constants, serves etc. should be declared here.

local camera = Image.Provider.Camera.create()
Image.Provider.Camera.stop(camera)

local threshold = 100  -- The threshold. If a pixel differs more than this much between two images, the pixel is removed

local deco = View.ImageDecoration.create()
deco:setRange(0, 10000)
local viewer = View.create("2DViewer")
local previousImage = nil

--End of Global Scope-----------------------------------------------------------


--Start of Function and Event Scope---------------------------------------------

---Declaration of the 'main' function as an entry point for the event loop
local function main()
  Image.Provider.Camera.start(camera)
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register("Engine.OnStarted", main)

---@param image Image
local function dynamicFilter(image)
  --store the datatype of the pixel
  local originalType = Image.getType(image)
  --convert the image to float32
  local currentImage = Image.toType(image, "FLOAT32")
  --ignore missing data
  currentImage:setMissingDataFlag(false)
  local result
  if previousImage then
    --calcute the absolute of the difference image
    local diffImg = Image.abs(Image.subtract(currentImage, previousImage))
    --find all pixels that are above threshold
    local region = Image.threshold(diffImg, threshold)
    --set all found pixels to 0
    local filteredImage = Image.PixelRegion.fillRegion(region, 0, currentImage)
    --set the image type to the type of the stored image
    result = Image.toType(filteredImage, originalType)
  else
    result = image
  end
  --store the most recent image to use it as the last image in the next iteration
  previousImage = currentImage

  return result
end

---@param image Image
---@param sensordata SensorData
local function handleOnNewImage(image)
  local img = dynamicFilter(image[1])
  View.addImage(viewer, img, deco)
  View.present(viewer)
end
Image.Provider.Camera.register(camera,"OnNewImage",handleOnNewImage)