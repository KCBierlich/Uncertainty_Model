data_plan = drake_plan(
  
  #
  # training data
  #
  
  # in-field training data
  Calibration_Data = read.csv(file_in(!!(
    file.path('data', 'calibration_object-measurements.csv')
  ))),
  
  # load error experiment training data
  APE = read.csv(file_in(!!file.path('data', 'APE-Dataset.csv'))) %>% 
    dplyr::mutate(
      Sw = 23.5,
      Iw = 6000
    ),
  
  # training object information (m)
  training_obj = rbind(
    data.frame(
      Subject = 'Training object',
      Measurement = 'Total length',
      Length = 1.48
    ), 
    Calibration_Data %>% 
      dplyr::select(Subject = CO.ID, Length = CO.Length) %>% 
      unique() %>% 
      dplyr::mutate(Measurement = 'Total length')
  ),
  
  # filter UAS from APE dataset to be used as training data
  APE_filtered = APE %>% dplyr::filter(
    Aircraft %in% c('LemHex', 'Alta-35mm', 'Alta-50mm'),
    Altimeter == 'Barometer',
    Measurer == 'KCB',
    is.finite(Baro...Ht),
    is.finite(Laser_Alt)
  ),
  
  # filter dataset for training data
  Calibration_filtered = Calibration_Data %>% dplyr::filter(
    # Aircraft %in% c('Alta', 'LemHex'),
    Altimeter == 'barometer',
    Analyst == 'KCB',
    is.finite(Baro.Ht),
    is.finite(Laser_Alt)
  ),

  # extract standardized information about images
  APE_images = APE_filtered %>%
    dplyr::mutate(
      Image = Images,
      AltitudeBarometer = Baro...Ht,
      AltitudeLaser = Laser_Alt,
      FocalLength = Focal.length,
      ImageWidth = Iw,
      SensorWidth = Sw
    ) %>%
    dplyr::select(
      Image, AltitudeBarometer, AltitudeLaser, FocalLength, ImageWidth,
      SensorWidth
    ),
  
  # extract standardized information about images
  Calibration_images = Calibration_filtered %>%
    dplyr::select(
      Image, 
      AltitudeBarometer = Baro.Ht,
      AltitudeLaser = Laser_Alt,
      FocalLength = Focal_Length,
      ImageWidth = Iw,
      SensorWidth = Sw
    ),

  # extract standardized information about pixel counts
  APE_pixels = APE_filtered %>%
    dplyr::mutate(
      Subject = 'Training object',
      Measurement = 'Total length',
      Image = Images,
      PixelCount = RRR.pix,
      EmpiricalLength = RRR.pix * Altitude * Sw / (Iw * Focal.length),
      EmpiricalBarometerLength = RRR.pix * Baro...Ht * Sw / (Iw * Focal.length),
      EmpiricalLaserLength = RRR.pix * Laser_Alt * Sw / (Iw * Focal.length)
    ) %>%
    dplyr::select(
      Subject, Measurement, Image, PixelCount, EmpiricalLength, 
      EmpiricalBarometerLength, EmpiricalLaserLength
    ),
  
  # extract standardized information about pixel counts
  Calibration_pixels = Calibration_filtered %>%
    dplyr::mutate(
      Measurement = 'Total length',
      EmpiricalLength = Lpix * Altitude * Sw / (Iw * Focal_Length),
      EmpiricalBarometerLength = Lpix * Baro.Ht * Sw / (Iw * Focal_Length),
      EmpiricalLaserLength = Lpix * Laser_Alt * Sw / (Iw * Focal_Length),
    ) %>%
    dplyr::select(
      Subject = CO.ID,
      Measurement,
      Image,
      PixelCount = Lpix,
      EmpiricalLength,
      EmpiricalBarometerLength,
      EmpiricalLaserLength
    ),
    
  
  #
  # observation study
  #

  # load observations of whales
  Mns = read.csv(file_in(!!file.path('data', 'humpback_data.csv'))) %>% 
    dplyr::mutate(
      Iw = 6000,
      Sw = 23.5
    ),

  Mns_filtered = Mns %>%
    # Create variables for focal length and altimeter of each aircraft
    dplyr::mutate(uas = paste(Aircraft, Focal_Length, sep = '-')) %>% 
    # Remove LemHex w/50 mm focal length b/c this was not in APE experiment.
    dplyr::filter(uas != 'LemHex-50') %>% 
    # filter out images with only a barometer since all images that have a 
    # laser reading for altitude will also have a barometer reading,
    dplyr::filter(Altimeter != 'barometer'),
    
  # extract standardized information about images
  Mns_images = Mns_filtered %>%
    dplyr::mutate(
      AltitudeBarometer = BaroAlt,
      AltitudeLaser = as.numeric(format(LaserAlt)),
      FocalLength = Focal_Length,
      ImageWidth = Iw,
      SensorWidth = Sw
    ) %>%
    dplyr::select(
      Image, AltitudeBarometer, AltitudeLaser, FocalLength, ImageWidth,
      SensorWidth
    ),
  
  # extract standardized information about pixel counts
  Mns_pixels = Mns_filtered %>%
    dplyr::mutate(
      Subject = Animal_ID,
      Measurement = 'Total length',
      # recover pixel counts from empirical, barometer-based TL estimates
      PixelCount = TL * Focal_Length * Iw / (Altitude * Sw),
      EmpiricalLength = TL,
      EmpiricalBarometerLength = PixelCount * 
        BaroAlt * Sw / (Iw * Focal_Length),
      EmpiricalLaserLength = PixelCount * 
        as.numeric(LaserAlt) * Sw / (Iw * Focal_Length)
    ) %>%
    dplyr::select(
      Subject, Measurement, Image, PixelCount, EmpiricalLength,
      EmpiricalBarometerLength, EmpiricalLaserLength
    ),
  
  
  #
  # physiological relation study
  #
  
  # load morphological measurements
  Marrs_amws = read.csv(file_in(!!file.path('data', 'marrs_amws.csv'))),
  
  Marrs_filtered = Marrs_amws %>% 
    dplyr::filter(
      # target morphological measurements must be available
      is.finite(TL), is.finite(RB), 
      # some altitude data must be present 
      any(is.finite(LaserAlt), is.finite(BaroAlt))
    ),
  
  # extract standardized information about images
  Marrs_images = Marrs_filtered %>%
    dplyr::mutate(
      AltitudeBarometer = BaroAlt + Launch_Ht,
      AltitudeLaser = LaserAlt,
      FocalLength = Focal_Length,
      ImageWidth = Iw,
      SensorWidth = Sw
    ) %>% 
    dplyr::select(
      Image, AltitudeBarometer, AltitudeLaser, FocalLength, ImageWidth, 
      SensorWidth
    ),
  
  # extract standardized information about pixel counts
  Marrs_pixels = Marrs_filtered %>% 
    pivot_longer(cols = c('TL', 'RB'), names_to = 'Measurement', 
                 values_to = 'value') %>%
    dplyr::mutate(
      Subject = AID,
      # recover pixel counts from empirical estimates
      PixelCount = value * Focal_Length * Iw / (Altitude * Sw),
      EmpiricalLength = value,
      EmpiricalBarometerLength = PixelCount * 
        BaroAlt * Sw / (Iw * Focal_Length),
      EmpiricalLaserLength = PixelCount * 
        LaserAlt * Sw / (Iw * Focal_Length)
    ) %>%
    dplyr::select(
      Subject, Measurement, Image, PixelCount, EmpiricalLength,
      EmpiricalBarometerLength, EmpiricalLaserLength
    )

)
