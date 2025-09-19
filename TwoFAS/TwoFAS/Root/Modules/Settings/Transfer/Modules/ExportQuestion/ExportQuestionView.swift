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

import SwiftUI
import Common

struct ExportQuestionView: View {
    @StateObject
    var presenter: ExportQuestionPresenter
    let exportType: ExportQuestionType
    
    @State private var enableSave = false
    private let spacing = ThemeMetrics.spacing
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: spacing) {
                    Spacer()
                    
                    Asset.exportBackup.swiftUIImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 280, height: 200)
                    
                    Spacer()
                    
                    Text(exportType.title)
                        .font(.title)
                        .fontWeight(.light)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .padding(.horizontal, 2 * spacing)
                .frame(width: Theme.Metrics.componentWidth, alignment: .center)
                
                VStack(spacing: 3 * spacing) {
                    VStack {
                        Text(exportType.message)
                            .font(.body)
                            .minimumScaleFactor(0.8)
                        
                        Spacer()
                        
                        Toggle(T.Exportwarning.toggle, isOn: $enableSave)
                            .tint(Color(ThemeColor.theme))
                            .font(.body)
                    }
                    .padding(.horizontal, 2 * spacing)
                    
                    VStack(spacing: ThemeMetrics.spacing) {
                        Button(action: {
                            presenter.handleShowPIN()
                        }) {
                            Text(exportType.cta)
                        }
                        .buttonStyle(RoundedFilledConstantWidthStateButtonStyle(isDisabled: !enableSave))
                        .disabled(!enableSave)
                        
                        Button(action: {
                            presenter.handleClose()
                        }) {
                            Text(T.Commons.cancel)
                        }
                        .buttonStyle(TextLinkButtonStyle())
                    }
                }
                .padding(.horizontal, 2 * spacing)
                .background(Color(Theme.Colors.Fill.background))
            }
            .navigationBarHidden(true)
            .frame(alignment: .center)
        }
    }
}

private extension ExportQuestionType {
    var title: String {
        switch self {
        case .file: T.Exportwarning.titleFile
        case .qr: T.Exportwarning.titleQr
        }
    }
    
    var message: String {
        switch self {
        case .file: T.Exportwarning.descriptionFile
        case .qr: T.Exportwarning.descriptionQr
        }
    }
    
    var cta: String {
        switch self {
        case .file: T.Exportwarning.ctaFile
        case .qr: T.Exportwarning.ctaQr
        }
    }
}
