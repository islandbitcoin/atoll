# Atoll

Atoll is Island Bitcoin’s independent registry for StartOS and community app store for Umbrel. [Browse the Atoll catalog](https://islandbitcoin.github.io/atoll/) to see the available services, versions and supported platforms.

## Add Atoll to StartOS

1. On StartOS 0.4.2 or later, open **System → Registries → Add registry**.
2. Enter `https://start9.bobodread.com` and add the registry.
3. Open **Marketplace**, select **Atoll Registry** above the search field, then choose a service and select **Install**.

When you add a registry, StartOS trusts newly offered keys for **Packages**. To check Atoll’s package-signing key, open **System → Registries**, open Atoll’s menu and select **Manage keys**. The **Dread** key has the following SHA-256 fingerprint.

```text
SHA256:kDMXbVdasLTDl4qkaId2gdmJ087a1kTuTX0tYTK0IYc
```

For help with an Atoll package, [open an issue with Island Bitcoin](https://github.com/islandbitcoin/atoll/issues). Start9’s [Marketplace guide](https://docs.start9.com/start-os/marketplace.html) explains registry and signer settings.

## Add Atoll to Umbrel

Open **App Store → ⋯ → Add community store** and enter `https://github.com/islandbitcoin/atoll-store`. Open the **Island Bitcoin** store to choose an app.

## For maintainers

- **StartOS packages.** The [registry guide](registry/README.md) covers building and signing a package locally, importing a reviewed build from another registry, and refreshing the catalog with `make sync`.
- **Umbrel apps.** Each app has its own directory in the [Atoll store repository](https://github.com/islandbitcoin/atoll-store).
- **Atoll Recovery.** Use the [package instructions](https://github.com/islandbitcoin/atoll-recovery-startos/blob/main/instructions.md) for setup and recovery. The [beta.5 staging notes](https://github.com/islandbitcoin/atoll/blob/8570d9543175f7b299b9d8f8e326e2d2472da29b/README.md#atoll-recovery-prerelease) record what that release tested.
