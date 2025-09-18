//
//  This file is part of the 2FAS iOS app (https://github.com/twofas/2fas-ios)
//  Copyright © 2023 Two Factor Authentication Service, Inc.
//  Contributed by Zbigniew Cisiński. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see <https://www.gnu.org/licenses/>
//

import UIKit

struct TransferSection: TableViewSection {
    let title: String
    var cells: [TransferCell]
    let footer: String
}

struct TransferCell: Hashable {
    enum TransferAction: Hashable {
        case aegis
        case raivo
        case lastPass
        case googleAuth
        case andOTP
        case authenticatorPro
        case otpAuthFileImport
        case otpAuthFileExport
        case exportQRCodes
    }
    
    let icon: UIImage?
    let title: String
    let action: TransferAction
    let isActive: Bool
    
    init(icon: UIImage?, title: String, action: TransferAction, isActive: Bool = true) {
        self.icon = icon
        self.title = title
        self.action = action
        self.isActive = isActive
    }
}

extension TransferPresenter {
    func buildMenu() -> [TransferSection] {
        [
            TransferSection(
                title: T.Transfer.importSectionTitle,
                cells: [
                    .init(
                        icon: Asset.externalImportIconAegis.image,
                        title: T.externalimportAegis,
                        action: .aegis
                    ),
                    .init(
                        icon: Asset.externalImportIconRaivo.image,
                        title: T.externalimportRaivo,
                        action: .raivo
                    ),
                    .init(
                        icon: Asset.externalImportIconLastPass.image,
                        title: T.externalimportLastpass,
                        action: .lastPass
                    ),
                    .init(
                        icon: Asset.externalmportIconGoogleAuth.image,
                        title: T.externalimportGoogleAuthenticator,
                        action: .googleAuth
                    ),
                    .init(
                        icon: Asset.externalImportIconAndOTP.image,
                        title: T.externalimportAndotp,
                        action: .andOTP
                    ),
                    .init(
                        icon: Asset.externalImportIconAuthenticatorPro.image,
                        title: T.Externalimport.authenticatorpro,
                        action: .authenticatorPro
                    ),
                    .init(
                        icon: UIImage(systemName: "doc.fill")!,
                        title: T.Transfer.importOtpauthFile,
                        action: .otpAuthFileImport
                    )
                ],
                footer: T.externalimportDescription
            ),
            TransferSection(
                title: T.Transfer.exportSectionTitle,
                cells: [
                    .init(
                        icon: UIImage(systemName: "doc.fill")!,
                        title: T.Transfer.exportOtpFile,
                        action: .otpAuthFileExport,
                        isActive: interactor.hasServices
                    ),
                    .init(
                        icon: UIImage(systemName: "qrcode")!,
                        title: T.Transfer.exportOtpQr,
                        action: .exportQRCodes,
                        isActive: interactor.hasServices
                    )
                ],
                footer: T.Settings.exportOptionsFooter
            )
        ]
    }
}
