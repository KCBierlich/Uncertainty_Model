README
================

The code is designed to be run using the `drake` package, by running the
code in the script [make.R](make.R) either via the command line (i.e.,
`R CMD BATCH make.R`), or from within an interactive `R` session. The
outline of all project components (i.e., the `drake` plan) is available
in the [R/subplans](R/subplans) directory.

The `drake` [Github page](https://github.com/ropensci/drake) page has a
good overview of what drake does, and includes some code snippets. After
running the [make.R](make.R) script, the `drake::loadd` function is the
most helpful function for loading output.

The `drake` [documentation](https://books.ropensci.org/drake/index.html)
itself is also a good resource for learning how to use the `drake`
package.  
Starting with the
[Walkthrough](https://books.ropensci.org/drake/walkthrough.html#set-the-stage.)
is a decent place to just jump in to some details.

# Data formats

The Error measurement model is implemented in the
[model\_joint.R](R/nimble/model_joint.R) script. The model
implementation is abstract, to allow multiple observations of any
object. The [data\_plan.R](R/subplans/data_plan.R) script creates the
necessary, raw data structures for the model. The
[flatten\_data()](R/nimble/flatten_data.R) function munges the data
structures for use with the model’s implementation in `nimble`.

## Training object information

Each training object must be documented in the same format as the
`training_obj` object (below). The first two columns specify the
training object, and the third column records its known length. The
[flatten\_data()](R/nimble/flatten_data.R) function will use the
information in `training_obj` to associate known lengths with image and
pixel measurements of the training objects.

| Subject         | Measurement  | Length |
| :-------------- | :----------- | -----: |
| Training object | Total length |  1.480 |
| WAP-180611      | Total length |  1.400 |
| WAP-180305      | Total length |  1.330 |
| CA-180906       | Total length |  1.270 |
| CA-170813       | Total length |  1.525 |
| NC-190626       | Total length |  1.480 |

## Image data

Each image must be documented in the same format as the `Mns_images`
object (preview below). The first column `Image` provides a unique
identifier for the image and will be used to create an altitude
variable, which will be estimated from the altitude sensor readings
provided by `AltitudeBarometer` and `AltitudeLaser` in conjunction with
training data. The remaining columns in `Mns_images` report the focal
length (mm), image width (pixels), and camera sensor width (mm)
associated with the image, which will be used to estimate the image’s
ground sampling distance (GSD) per pixel.

| Image                       | AltitudeBarometer | AltitudeLaser | FocalLength | ImageWidth | SensorWidth |
| :-------------------------- | ----------------: | ------------: | ----------: | ---------: | ----------: |
| 190303\_A\_F5\_DSC07951.JPG |             17.45 |         16.72 |          35 |       6000 |        23.5 |
| 190305\_A\_F2\_DSC08581.JPG |             25.46 |         23.75 |          35 |       6000 |        23.5 |
| 190303\_A\_F1\_DSC07542.JPG |             24.08 |         23.91 |          35 |       6000 |        23.5 |
| 190224\_L\_F2\_DSC04640.JPG |             27.15 |         24.37 |          35 |       6000 |        23.5 |
| 190303\_A\_F4\_DSC07613.JPG |             25.13 |         24.79 |          35 |       6000 |        23.5 |

## Pixel count “measurement” data

All pixel measurements must also be documented in the same format as the
`Mns_pixels` object (preview below). The first two columns specify the
measurement. One measurement variable, which will be estimated, will be
associated with each unique combination of the first two columns. The
`Image` column links the measurement to an image and it’s estimated GSD.
Lastly, the `PixelCount` column records the pixel-length of the object
as it appears in the image.

|   | Subject                  | Measurement  | Image                       | PixelCount | EmpiricalLength | EmpiricalBarometerLength | EmpiricalLaserLength |
| :- | :----------------------- | :----------- | :-------------------------- | ---------: | --------------: | -----------------------: | -------------------: |
| 3 | Mn190303\_A\_F1-01       | Total length | 190303\_A\_F1\_DSC07542.JPG |   4434.894 |       11.866191 |                11.950560 |            11.866191 |
| 4 | Mn190224\_L\_F2-04-mom   | Total length | 190224\_L\_F2\_DSC04640.JPG |   4800.000 |       13.090171 |                14.583429 |            13.090171 |
| 5 | Mn190303\_A\_F4-09-mom1  | Total length | 190303\_A\_F4\_DSC07613.JPG |   4253.617 |       11.800040 |                11.961880 |            11.800040 |
| 6 | Mn170204\_A\_F3\_06-calf | Total length | 170204\_A\_F3\_DSC00964.JPG |   3750.638 |        7.286240 |                 9.119552 |             7.286240 |
| 7 | Mn190226\_L\_F1-01-mom   | Total length | 190226\_L\_F1\_DSC05462.JPG |   4549.787 |       13.339543 |                13.135886 |            13.339543 |
| 8 | Mn190224\_L\_F2-05-calf  | Total length | 190224\_L\_F2\_DSC04569.JPG |   2765.106 |        8.243177 |                 8.540229 |             8.243177 |

## Many-to-Many relationships

Storing Image and Pixel count data in separate structures allows
multiple measurements to be estimated from a single image. For example,
total length and maximum width can be measured from the same image
through a pixel count table like the following:

| Subject  | Measurement  | Image   | PixelCount |
| :------- | :----------- | :------ | ---------: |
| Animal A | Total length | Image 1 |       1000 |
| Animal A | Max. width   | Image 1 |        100 |

Both `PixelCount` entries above relate to a different object being
measured, but use the same estimated altitude and implied GSD for
`Image 1` when estimating lengths from pixel counts.

Similarly, the Image and Pixel count structures also allow one object to
be estimated from multiple images. For example, total length can be
estimated from multiple observations through a pixel count table like
the following:

| Subject  | Measurement  | Image   | PixelCount |
| :------- | :----------- | :------ | ---------: |
| Animal A | Total length | Image 1 |  1000.0000 |
| Animal A | Total length | Image 2 |  1017.7011 |
| Animal A | Total length | Image 3 |   985.3995 |
| Animal A | Total length | Image 4 |  1023.0340 |
| Animal A | Total length | Image 5 |   999.4977 |

## Materials

### Data:

“APE-Dataset.csv” - training/calibration data for different UAS
platforms.

Images = image used for measuring calibration object Aircraft = the UAS
aircraft used to collect imagery of calibration object to measure Flight
= the flight number/name Position = indicates if calibration object is
in center of corner of image frame Focal.length = focal length of camera
Pix.Dim = pixel dimensions (mm/px), which is the sensor width (mm) /
image width (px) of the camera Baro\_raw = the raw relative altitude
recorded by the barometer Launch.Ht = the launch height of the drone, to
be added to the BarAlt to get the absolute barometric altitude above the
surface of the water Baro + Ht = the baro\_raw + Launch.Ht to get the
absolute barometer altitude Laser\_Alt = the altitude recorded by the
laser altimeter. Blanks spaces/NAs indicate no/false reading Alitude =
altitude used in measurement, either Laser\_Alt or Baro + Ht Alimeter =
which altimeter was used for altitude in measurement; either barometer
or laser Measurer = which analyst measured the calibration object (3
analysts total, measured each image once) RRR.pix = the length in pixels
of the known sized object (calibration object)

\*“humpback\_data.csv” - testing data. Humpback lengths from the Western
Antarctic Peninsula.

\+Animal\_ID = unique ID for individual whale +Reproductive\_Class =
determined from biopsy sample or from drone images (mom and calf pairs)
+Species = the species of whale +Image = the image ID used for measuring
the whale +Aircraft = which UAS platform collected the imagery
+Focal\_Length = focal length (mm) of the camera used +LaserAlt = the
altitude recorded by the laser altimeter. Blanks spaces/NAs indicate
no/false reading +BaroAlt = the raw relative altitude recorded by the
barometer +Pixel\_Dimension = (mm/px) the Sensor width (mm) / Image
width (px) of the camera +Launch\_Ht = the launch height of the drone,
to be added to the BarAlt to get the absolute barometric altitude above
the surface of the water +Altitude = altitude used in measurement,
either LaserAlt or BaroAlt + Launch\_Ht +Altimeter = which altimeter was
used for altitude in measurement; either barometer or laser +TL = total
length of the whale in meters
