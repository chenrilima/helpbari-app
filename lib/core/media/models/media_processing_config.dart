class MediaProcessingConfig {
  const MediaProcessingConfig({
    this.compressImages = true,
    this.cropImages = false,
    this.imageQuality = 82,
    this.minImageWidth = 1080,
    this.minImageHeight = 1080,
    this.cacheFiles = true,
  });

  final bool compressImages;
  final bool cropImages;
  final int imageQuality;
  final int minImageWidth;
  final int minImageHeight;
  final bool cacheFiles;
}
