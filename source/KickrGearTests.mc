// Optional simulator unit tests. Synthetic packets, not hardware captures.
(:test)
function testKickrDecode(logger) {
    var middle = decodeKickrGearPacket([0, 0, 1, 6, 2, 12]b);
    if (middle == null || middle[0] != 2 || middle[1] != 7 ||
        middle[2] != 2 || middle[3] != 12) { return false; }
    var first = decodeKickrGearPacket([0, 0, 0, 0, 1, 12]b);
    if (first == null || first[0] != 1 || first[1] != 1) { return false; }
    var last = decodeKickrGearPacket([0, 0, 1, 11, 2, 12]b);
    if (last == null || last[0] != 2 || last[1] != 12) { return false; }
    if (decodeKickrGearPacket([0, 0, 2, 0, 2, 12]b) != null) { return false; }
    if (decodeKickrGearPacket([0, 0, 1, 12, 2, 12]b) != null) { return false; }
    if (decodeKickrGearPacket([0, 0, 0, 0, 0, 12]b) != null) { return false; }
    if (decodeKickrGearPacket([0, 0, 0, 0, 1, 0]b) != null) { return false; }
    if (decodeKickrGearPacket([0, 0, 0]b) != null) { return false; }
    if (decodeKickrGearPacket(null) != null) { return false; }
    logger.debug("Kickr decoder: synthetic cases passed");
    return true;
}
