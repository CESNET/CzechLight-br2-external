# Isn't this horribly insecure?

Yes, there is a private key in a publicly accessible git repository.
We have decided that this is not a security problem for us.

These keys control signing of FW images which might be -- eventually -- deployed to devices.
Now that the key has been effectively leaked, that implies that anyone can produce a malicious FW image which will still be accepted via RAUC.
We are not relying on signature verification for FW image installations; we're just using that as a better checksum control.
We're using RAUC and we've ensured that only root can invoke a `rauc install ...`, which means that nobody but root can install a malicious image.
Root can already do *anything* on these devices, and that's by design, we are not using signed boot images verified by the boot loader, or anything like that, really.
So what we've lost is a safeguard from RAUC saying "hey, that FW image that you're downloading, that has not been produced by CESNET".

If we used a "real setup" with a proper CA and key management, we would probably have one certificate chain for "development builds" in the CI, and some re-signing for images that have been "approved" (merged patches).
We would also require something for developers' local workflow with transient keys, probably short-lived ones.
We would have to set up some key management.
We would have also needed to define a process on how to configure a device to accept the development images.

However, any developer is allowed to propose patches, and these patches would get auto-signed by the CI anyway.
Granted, it would not be the "production signature", but these boxes will *have* to accept these devel signatures anyway.
We would also have to deal with the back-and-forth of key signing and certificate renewal.

What we chose instead is to "disable" RAUC signature verification.
Now that anyone in the world can build an image and have it signed, we have downgraded RAUC's signature checking to a glorified checksum.

TL;DR: this means that we are effectively not using RAUC's image verification.
