enum MediaFileType {
  image,
  pdf;

  bool get isImage => this == MediaFileType.image;

  bool get isPdf => this == MediaFileType.pdf;
}
