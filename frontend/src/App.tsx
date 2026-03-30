import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'

import { AuthProvider, useAuth } from './auth/AuthContext'
import { ConfirmProvider } from './components/confirm/ConfirmProvider'
import LoginPage from './features/auth/LoginPage'
import AdminLayout from './features/admin/AdminLayout'
import { ProtectedRoute } from './features/admin/ProtectedRoute'
import TypesPage from './features/admin/TypesPage'
import FormatsPage from './features/admin/FormatsPage'
import ProductsPage from './features/admin/ProductsPage'
import './styles/bts.css'

function HomeRedirect() {
  const { isAuthenticated } = useAuth()
  return <Navigate to={isAuthenticated ? '/admin/produits' : '/login'} replace />
}

export default function App() {
  return (
    <AuthProvider>
      <ConfirmProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/" element={<HomeRedirect />} />
            <Route path="/login" element={<LoginPage />} />

            <Route
              path="/admin"
              element={
                <ProtectedRoute>
                  <AdminLayout />
                </ProtectedRoute>
              }
            >
              <Route path="produits" element={<ProductsPage />} />
              <Route path="types" element={<TypesPage />} />
              <Route path="formats" element={<FormatsPage />} />
            </Route>
          </Routes>
        </BrowserRouter>
      </ConfirmProvider>
    </AuthProvider>
  )
}
