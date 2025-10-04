 template <typename T, typename U>
  int binarySearchAnyList(const T& ParticleList, const U& key)
  {
    if (ParticleList.empty())
      return -1;
    int low = 0;
    int high = ParticleList.size() - 1;
    while (low <= high) {
      int mid = low + (high - low) / 2;
      if (ParticleList[mid] == key) {
        return mid;
      }
      if (ParticleList[mid] < key)
        low = mid + 1;
      else
        high = mid - 1;
    }
    return -1; // If we reach here, then element was not present
  }
